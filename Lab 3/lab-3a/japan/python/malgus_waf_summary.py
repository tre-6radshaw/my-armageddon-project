#!/usr/bin/env python3
"""
malgus_waf_summary.py

Summarize AWS WAF logs (ALLOW vs BLOCK) from a CloudWatch Logs destination and write proof to:
  ./lab3-audit-pack/03_waf-proof.txt

Auto-detection built in:
- If the specified log group is not found in the provided --region, the script will
  automatically search these common regions (in order) to locate it:
    1) region you passed via --region
    2) us-east-1 (common for CloudFront-associated WAF logging)
    3) ap-northeast-1 (Tokyo)
    4) sa-east-1 (São Paulo)

Requirements:
- Python 3.8+
- boto3: pip3 install boto3
- AWS credentials configured

Examples:
python3 malgus_waf_summary.py --hours 24
python3 malgus_waf_summary.py --log-group aws-waf-logs-gru-webacl01 --hours 24
python3 malgus_waf_summary.py --region us-east-1 --log-group aws-waf-logs-gru-webacl01 --hours 24
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Tuple

import boto3
from botocore.exceptions import ClientError, NoCredentialsError

# ---------- OUTPUT LOCATION (FIXED) ----------
AUDIT_DIR = Path(__file__).parent / "lab3-audit-pack"
OUTPUT_FILE = AUDIT_DIR / "03_waf-proof.txt"
# -------------------------------------------

# Default log group you used earlier in your lab outputs
DEFAULT_LOG_GROUP = "aws-waf-logs-gru-webacl01"

# Common regions to try for WAF logs in your lab context
TOKYO_REGION = "ap-northeast-1"
SAOPAULO_REGION = "sa-east-1"
CLOUDFRONT_COMMON_REGION = "us-east-1"


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def utc_stamp() -> str:
    return utc_now().strftime("%Y%m%dT%H%M%SZ")


def to_epoch_ms(dt: datetime) -> int:
    return int(dt.timestamp() * 1000)


def logs_client(region: str):
    return boto3.client("logs", region_name=region)


def safe_json(line: str) -> Optional[Dict[str, Any]]:
    try:
        return json.loads(line)
    except Exception:
        return None


def get_action(record: Dict[str, Any]) -> str:
    """
    Best-effort extraction of ALLOW/BLOCK/COUNT.
    Field names can vary; try common locations defensively.
    """
    act = record.get("action")
    if isinstance(act, str) and act:
        return act.upper()

    # Some variants nest under httpRequest (rare)
    http_req = record.get("httpRequest")
    if isinstance(http_req, dict):
        act2 = http_req.get("action")
        if isinstance(act2, str) and act2:
            return act2.upper()

    return "UNKNOWN"


def get_terminating_rule(record: Dict[str, Any]) -> str:
    tr = record.get("terminatingRuleId")
    if isinstance(tr, str) and tr:
        return tr

    # Some variants include terminatingRule inside ruleGroupList
    rgl = record.get("ruleGroupList")
    if isinstance(rgl, list):
        for g in rgl:
            if isinstance(g, dict) and g.get("terminatingRule"):
                t = g.get("terminatingRule")
                if isinstance(t, dict) and isinstance(t.get("ruleId"), str):
                    return t["ruleId"]

    return "-"


def get_country(record: Dict[str, Any]) -> str:
    http_req = record.get("httpRequest")
    if isinstance(http_req, dict):
        c = http_req.get("country")
        if isinstance(c, str) and c:
            return c.upper()
    return "-"


def get_client_ip(record: Dict[str, Any]) -> str:
    http_req = record.get("httpRequest")
    if isinstance(http_req, dict):
        ip = http_req.get("clientIp")
        if isinstance(ip, str) and ip:
            return ip
    return "-"


def get_uri(record: Dict[str, Any]) -> str:
    http_req = record.get("httpRequest")
    if isinstance(http_req, dict):
        uri = http_req.get("uri")
        if isinstance(uri, str) and uri:
            return uri
    return "-"


def stream_events(
    client,
    log_group: str,
    start_ms: int,
    end_ms: int,
    limit: int,
):
    """
    Streams log events using filter_log_events with pagination.
    """
    next_token: Optional[str] = None
    fetched = 0

    while True:
        args: Dict[str, Any] = {
            "logGroupName": log_group,
            "startTime": start_ms,
            "endTime": end_ms,
            "limit": min(10000, max(1, limit - fetched)),
        }
        if next_token:
            args["nextToken"] = next_token

        resp = client.filter_log_events(**args)

        events = resp.get("events", [])
        for e in events:
            yield e
            fetched += 1
            if fetched >= limit:
                return

        next_token = resp.get("nextToken")
        if not next_token or not events:
            return


def log_group_exists(client, log_group: str) -> bool:
    """
    Confirm the exact log group exists in this region.
    Using describe_log_groups with exact name prefix, then exact match check.
    """
    # CloudWatch Logs doesn't have an "exact" describe call; do prefix then verify.
    resp = client.describe_log_groups(logGroupNamePrefix=log_group, limit=50)
    names = [g.get("logGroupName") for g in resp.get("logGroups", [])]
    return log_group in names


def autodetect_log_group_region(preferred_region: str, log_group: str) -> Tuple[str, Any]:
    """
    Try the preferred region first, then common regions where WAF logs often live.
    Returns (detected_region, logs_client).
    Raises SystemExit if not found.
    """
    candidates: List[str] = []
    if preferred_region:
        candidates.append(preferred_region)

    # add common regions, preserving order, and avoiding duplicates
    for r in [CLOUDFRONT_COMMON_REGION, TOKYO_REGION, SAOPAULO_REGION]:
        if r not in candidates:
            candidates.append(r)

    last_errors: List[str] = []

    for region in candidates:
        c = logs_client(region)
        try:
            if log_group_exists(c, log_group):
                return region, c
        except ClientError as e:
            last_errors.append(f"{region}: {e.response.get('Error', {}).get('Code', 'ClientError')}")
            continue

    msg = (
        f"ERROR: CloudWatch log group '{log_group}' was not found in regions tried: {candidates}\n"
        "Fix:\n"
        "  1) List WAF log groups in us-east-1 (common for CloudFront):\n"
        "     aws logs describe-log-groups --region us-east-1 --log-group-name-prefix aws-waf-logs --output table\n"
        "  2) List WAF log groups in Tokyo:\n"
        "     aws logs describe-log-groups --region ap-northeast-1 --log-group-name-prefix aws-waf-logs --output table\n"
        "  3) Then re-run with --log-group <exact_name> and optionally --region <region>\n"
    )
    if last_errors:
        msg += "\nNotes (API errors while searching):\n  - " + "\n  - ".join(last_errors) + "\n"
    raise SystemExit(msg)


@dataclass
class WafSummary:
    total: int = 0
    allow: int = 0
    block: int = 0
    count: int = 0
    unknown: int = 0
    unparsed_lines: int = 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Summarize AWS WAF logs (ALLOW vs BLOCK) from CloudWatch Logs and write 03_waf-proof.txt"
    )
    parser.add_argument(
        "--log-group",
        default=DEFAULT_LOG_GROUP,
        help=f"CloudWatch log group name for WAF logs (default: {DEFAULT_LOG_GROUP})",
    )
    parser.add_argument(
        "--region",
        default=TOKYO_REGION,
        help=f"Preferred region to check first (default: {TOKYO_REGION}). "
             f"Auto-detection will also try {CLOUDFRONT_COMMON_REGION} if needed.",
    )
    parser.add_argument("--hours", type=int, default=24, help="How many hours back to summarize (default: 24).")
    parser.add_argument("--max-events", type=int, default=20000, help="Maximum events to process (default: 20000).")
    args = parser.parse_args()

    # Credentials sanity (separate from Logs region)
    try:
        boto3.client("sts").get_caller_identity()
    except NoCredentialsError:
        print("ERROR: AWS credentials not found. Run `aws sts get-caller-identity` first.", file=sys.stderr)
        return 2
    except ClientError as e:
        print(f"ERROR: AWS credential/API error: {e}", file=sys.stderr)
        return 2

    if args.hours < 1:
        print("ERROR: --hours must be >= 1", file=sys.stderr)
        return 2

    end = utc_now()
    start = end - timedelta(hours=args.hours)

    # Auto-detect region that actually contains the log group
    detected_region, client = autodetect_log_group_region(args.region, args.log_group)

    summary = WafSummary()
    block_rules = Counter()
    countries = Counter()
    client_ips = Counter()
    uris = Counter()

    try:
        for ev in stream_events(
            client=client,
            log_group=args.log_group,
            start_ms=to_epoch_ms(start),
            end_ms=to_epoch_ms(end),
            limit=max(1, args.max_events),
        ):
            rec = safe_json(ev.get("message", ""))
            if not rec:
                summary.unparsed_lines += 1
                continue

            summary.total += 1
            action = get_action(rec)

            if action == "ALLOW":
                summary.allow += 1
            elif action == "BLOCK":
                summary.block += 1
                block_rules[get_terminating_rule(rec)] += 1
            elif action == "COUNT":
                summary.count += 1
            else:
                summary.unknown += 1

            countries[get_country(rec)] += 1
            ip = get_client_ip(rec)
            if ip != "-":
                client_ips[ip] += 1
            uri = get_uri(rec)
            if uri != "-":
                uris[uri] += 1

    except ClientError as e:
        print(f"ERROR: CloudWatch Logs API error while reading events: {e}", file=sys.stderr)
        return 2

    # Ensure audit folder exists and write proof file
    AUDIT_DIR.mkdir(parents=True, exist_ok=True)

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write("03 — WAF LOG SUMMARY PROOF\n")
        f.write("==========================\n\n")
        f.write(f"Generated (UTC): {utc_stamp()}\n")
        f.write(f"Log Group: {args.log_group}\n")
        f.write(f"Region (detected): {detected_region}\n")
        f.write(f"Time window (UTC): {start.isoformat()}  →  {end.isoformat()}  (last {args.hours} hours)\n")
        f.write("WAF logging destination: CloudWatch Logs\n")
        f.write("Other valid WAF logging destination: S3\n\n")

        f.write("SUMMARY COUNTS\n")
        f.write("--------------\n")
        f.write(f"Total records processed: {summary.total}\n")
        f.write(f"ALLOW: {summary.allow}\n")
        f.write(f"BLOCK: {summary.block}\n")
        f.write(f"COUNT: {summary.count}\n")
        f.write(f"UNKNOWN: {summary.unknown}\n")
        f.write(f"Unparsed lines (non-JSON/unexpected format): {summary.unparsed_lines}\n\n")

        f.write("TOP BLOCKING RULES (if any)\n")
        f.write("---------------------------\n")
        if summary.block == 0:
            f.write("- No BLOCK actions observed in this time window.\n")
        else:
            for r, c in block_rules.most_common(10):
                f.write(f"- {r}: {c}\n")
        f.write("\n")

        f.write("TOP COUNTRIES (if present)\n")
        f.write("--------------------------\n")
        if not countries:
            f.write("- (none)\n")
        else:
            for c, n in countries.most_common(10):
                f.write(f"- {c}: {n}\n")
        f.write("\n")

        f.write("TOP CLIENT IPs (if present)\n")
        f.write("---------------------------\n")
        if not client_ips:
            f.write("- (none)\n")
        else:
            for ip, n in client_ips.most_common(10):
                f.write(f"- {ip}: {n}\n")
        f.write("\n")

        f.write("TOP URIs (if present)\n")
        f.write("---------------------\n")
        if not uris:
            f.write("- (none)\n")
        else:
            for u, n in uris.most_common(10):
                f.write(f"- {u}: {n}\n")
        f.write("\n")

        f.write("AUDITOR NOTES\n")
        f.write("-------------\n")
        f.write("- This proof is generated by reading WAF log records from CloudWatch Logs.\n")
        f.write("- It summarizes request actions (ALLOW vs BLOCK) over the specified time window.\n")
        f.write("- If totals are 0, verify WAF logging is enabled and traffic is reaching the protected resource.\n")

    print(f"Proof file written to: {OUTPUT_FILE}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())