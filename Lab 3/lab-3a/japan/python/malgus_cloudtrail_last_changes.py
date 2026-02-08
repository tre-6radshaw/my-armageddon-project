#!/usr/bin/env python3
"""
malgus_cloudtrail_last_changes.py

Script 4 — CloudTrail Change Proof (TXT)

Pulls recent CloudTrail *Event history* (management events; 90-day record by default)
and writes an auditor-friendly "who changed what" proof file to:

  ./lab3-audit-pack/04_cloudtrail-change-proof.txt

2-region build:
- Tokyo: ap-northeast-1
- São Paulo: sa-east-1

Notes:
- CloudTrail Event History is regional. This script queries each region separately.
- Uses CloudTrail LookupEvents API (Event History), not S3-delivered CloudTrail logs.

This rewrite is based on your uploaded version. :contentReference[oaicite:0]{index=0}
"""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional

import boto3
from botocore.exceptions import ClientError, NoCredentialsError

DEFAULT_REGIONS = ["ap-northeast-1", "sa-east-1"]  # Tokyo, São Paulo

# ---------- OUTPUT LOCATION ----------
AUDIT_DIR = Path(__file__).parent / "lab3-audit-pack"
OUTPUT_FILE = AUDIT_DIR / "04_cloudtrail-change-proof.txt"
# -----------------------------------


def utc_stamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")


def parse_regions(csv: str) -> List[str]:
    items = [r.strip() for r in csv.split(",") if r.strip()]
    return items or DEFAULT_REGIONS


def cloudtrail(region: str):
    return boto3.client("cloudtrail", region_name=region)


def safe_json_loads(s: str) -> Dict[str, Any]:
    try:
        return json.loads(s)
    except Exception:
        return {"raw": s}


def summarize_request_params(evt: Dict[str, Any]) -> str:
    rp = evt.get("requestParameters")
    if rp is None:
        return "-"
    try:
        rp_str = json.dumps(rp, ensure_ascii=False)
        if len(rp_str) > 350:
            rp_str = rp_str[:350] + "...(truncated)"
        return rp_str
    except Exception:
        return str(rp)


def summarize_resources(evt: Dict[str, Any]) -> str:
    resources: List[str] = []

    for key in [
        "transitGatewayId",
        "transitGatewayAttachmentId",
        "transitGatewayRouteTableId",
        "routeTableId",
        "vpcId",
        "subnetId",
        "securityGroupId",
        "dbInstanceIdentifier",
        "loadBalancerArn",
        "webACLArn",
        "resourceArn",
        "arn",
        "bucketName",
    ]:
        val = (
            evt.get(key)
            or (evt.get("responseElements") or {}).get(key)
            or (evt.get("requestParameters") or {}).get(key)
        )
        if isinstance(val, str) and val:
            resources.append(f"{key}={val}")

    # Also include event 'resources' if present
    evtr = evt.get("resources")
    if isinstance(evtr, list):
        for r in evtr:
            if isinstance(r, dict):
                rn = r.get("resourceName")
                rt = r.get("resourceType")
                if rn or rt:
                    resources.append(f"resource[{rt}]={rn}")

    # Deduplicate while preserving order
    seen = set()
    uniq: List[str] = []
    for r in resources:
        if r not in seen:
            uniq.append(r)
            seen.add(r)

    return ", ".join(uniq[:10]) if uniq else "-"


def lookup_events_region(
    region: str,
    start_time: datetime,
    end_time: datetime,
    max_events: int,
    event_name_filter: Optional[str],
    username_filter: Optional[str],
) -> List[Dict[str, Any]]:
    client = cloudtrail(region)

    lookup_attrs = []
    if event_name_filter:
        lookup_attrs.append({"AttributeKey": "EventName", "AttributeValue": event_name_filter})
    if username_filter:
        lookup_attrs.append({"AttributeKey": "Username", "AttributeValue": username_filter})

    kwargs: Dict[str, Any] = {
        "StartTime": start_time,
        "EndTime": end_time,
        "MaxResults": 50,
    }
    if lookup_attrs:
        kwargs["LookupAttributes"] = lookup_attrs

    events: List[Dict[str, Any]] = []
    next_token: Optional[str] = None

    while True:
        if next_token:
            kwargs["NextToken"] = next_token
        resp = client.lookup_events(**kwargs)

        batch = resp.get("Events", [])
        events.extend(batch)

        if len(events) >= max_events:
            events = events[:max_events]
            break

        next_token = resp.get("NextToken")
        if not next_token:
            break

    return events


def format_event_block(region: str, e: Dict[str, Any]) -> str:
    event_time = e.get("EventTime")
    username = e.get("Username") or "-"
    event_name = e.get("EventName") or "-"
    event_source = e.get("EventSource") or "-"
    event_id = e.get("EventId") or "-"

    detail = safe_json_loads(e.get("CloudTrailEvent", "{}"))
    user_identity = detail.get("userIdentity") or {}
    principal = user_identity.get("arn") or user_identity.get("principalId") or "-"
    source_ip = detail.get("sourceIPAddress") or "-"
    user_agent = detail.get("userAgent") or "-"
    resources = summarize_resources(detail)
    request_params = summarize_request_params(detail)
    error_code = detail.get("errorCode")
    error_message = detail.get("errorMessage")

    lines = []
    lines.append(f"[{region}] {event_time}  {event_source}:{event_name}")
    lines.append(f"  User: {username} | Principal: {principal}")
    lines.append(f"  SourceIP: {source_ip}")
    lines.append(f"  Resources: {resources}")
    lines.append(f"  RequestParameters: {request_params}")
    if error_code or error_message:
        lines.append(f"  ERROR: {error_code or '-'} | {error_message or '-'}")
    lines.append(f"  EventId: {event_id}")
    lines.append(f"  UserAgent: {user_agent}")
    return "\n".join(lines)


def main() -> int:
    p = argparse.ArgumentParser(
        description='Generate CloudTrail "who changed what" proof (Event History) into lab3-audit-pack.'
    )
    p.add_argument(
        "--regions",
        default=",".join(DEFAULT_REGIONS),
        help="Comma-separated AWS regions to query (default: ap-northeast-1,sa-east-1).",
    )
    p.add_argument(
        "--days",
        type=int,
        default=7,
        help="Days back to search (1–90; default: 7).",
    )
    p.add_argument(
        "--max-events",
        type=int,
        default=200,
        help="Max events per region (default: 200).",
    )
    p.add_argument(
        "--event-name",
        default="",
        help='Optional exact EventName filter (e.g., "CreateTransitGatewayRoute").',
    )
    p.add_argument(
        "--username",
        default="",
        help='Optional exact Username filter as shown in CloudTrail.',
    )

    args = p.parse_args()
    regions = parse_regions(args.regions)
    days = args.days

    if days < 1:
        print("ERROR: --days must be >= 1", file=sys.stderr)
        return 2
    if days > 90:
        print("ERROR: --days must be <= 90 (CloudTrail Event History default retention).", file=sys.stderr)
        return 2

    max_events = max(1, args.max_events)
    event_name_filter = args.event_name.strip() or None
    username_filter = args.username.strip() or None

    end_time = datetime.now(timezone.utc)
    start_time = end_time - timedelta(days=days)
    stamp = utc_stamp()

    # Ensure audit folder exists
    AUDIT_DIR.mkdir(parents=True, exist_ok=True)

    # Credential sanity check
    try:
        boto3.client("sts").get_caller_identity()
    except NoCredentialsError:
        print("ERROR: No AWS credentials found. Run `aws sts get-caller-identity`.", file=sys.stderr)
        return 2
    except ClientError as e:
        print(f"ERROR: AWS credential/API error: {e}", file=sys.stderr)
        return 2

    try:
        with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
            f.write("04 — CLOUDTRAIL CHANGE PROOF\n")
            f.write("============================\n\n")
            f.write(f"Generated (UTC): {stamp}\n")
            f.write(f"Time window (UTC): {start_time.isoformat()}  →  {end_time.isoformat()}\n")
            f.write(f"Regions queried: {', '.join(regions)}\n")
            f.write("Source: CloudTrail Event History (LookupEvents) — management events (90-day record by default)\n")
            if event_name_filter:
                f.write(f"EventName filter: {event_name_filter}\n")
            if username_filter:
                f.write(f"Username filter: {username_filter}\n")
            f.write("\n")

            total_written = 0

            for region in regions:
                f.write(f"REGION: {region}\n")
                f.write("-" * 70 + "\n")

                events = lookup_events_region(
                    region=region,
                    start_time=start_time,
                    end_time=end_time,
                    max_events=max_events,
                    event_name_filter=event_name_filter,
                    username_filter=username_filter,
                )

                f.write(f"Events returned: {len(events)} (capped at {max_events})\n\n")

                # Sort by EventTime desc
                def key_fn(ev: Dict[str, Any]):
                    t = ev.get("EventTime")
                    return t if t is not None else datetime.fromtimestamp(0, tz=timezone.utc)

                for e in sorted(events, key=key_fn, reverse=True):
                    f.write(format_event_block(region, e))
                    f.write("\n\n")
                    total_written += 1

                if not events:
                    f.write("No events found in this time window.\n\n")

                f.write("\n")

            f.write("SUMMARY\n")
            f.write("-------\n")
            f.write(f"Total events included: {total_written}\n")
            f.write(
                "- Each entry documents the actor (Username/Principal), the API action (EventSource:EventName),\n"
                "  affected resources (when available), and key request parameters.\n"
            )

        print(f"Proof file written to: {OUTPUT_FILE}")
        return 0

    except ClientError as e:
        print(f"AWS API error: {e}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())