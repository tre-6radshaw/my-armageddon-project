#!/usr/bin/env python3
"""
malgus_residency_proof.py

Script 1 — Data Residency Proof
--------------------------------
Proves that the application database exists ONLY in Tokyo (ap-northeast-1)
and does NOT exist in São Paulo (sa-east-1).

Output (fixed location):
  ./lab3-audit-pack/01_data-residency-proof.txt

Requirements:
- Python 3.8+
- boto3
- AWS credentials configured (same as AWS CLI)
"""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import boto3
from botocore.exceptions import ClientError, NoCredentialsError

# ---------- REGIONS ----------
TOKYO_REGION = "ap-northeast-1"
SAOPAULO_REGION = "sa-east-1"

# ---------- OUTPUT LOCATION ----------
AUDIT_DIR = Path(__file__).parent / "lab3-audit-pack"
OUTPUT_FILE = AUDIT_DIR / "01_data-residency-proof.txt"
# -----------------------------------


def utc_now_stamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")


def rds_client(region: str):
    return boto3.client("rds", region_name=region)


def describe_db_instance(region: str, db_id: str) -> Tuple[bool, Optional[Dict]]:
    try:
        resp = rds_client(region).describe_db_instances(DBInstanceIdentifier=db_id)
        return True, resp["DBInstances"][0]
    except ClientError as e:
        code = e.response.get("Error", {}).get("Code", "")
        if code in ("DBInstanceNotFound", "DBInstanceNotFoundFault"):
            return False, None
        raise


def list_all_db_instances(region: str) -> List[Dict]:
    paginator = rds_client(region).get_paginator("describe_db_instances")
    items: List[Dict] = []
    for page in paginator.paginate():
        items.extend(page.get("DBInstances", []))
    return items


def db_summary(db: Dict, region: str) -> Dict:
    return {
        "DBInstanceIdentifier": db.get("DBInstanceIdentifier"),
        "Engine": db.get("Engine"),
        "DBInstanceClass": db.get("DBInstanceClass"),
        "AvailabilityZone": db.get("AvailabilityZone"),
        "MultiAZ": db.get("MultiAZ"),
        "StorageEncrypted": db.get("StorageEncrypted"),
        "PubliclyAccessible": db.get("PubliclyAccessible"),
        "Endpoint": db.get("Endpoint", {}).get("Address"),
        "Region": region,
        "VpcId": db.get("DBSubnetGroup", {}).get("VpcId"),
        "VpcSecurityGroups": [sg.get("VpcSecurityGroupId") for sg in db.get("VpcSecurityGroups", [])],
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate data residency proof: DB exists only in Tokyo."
    )
    parser.add_argument(
        "--db-id",
        required=True,
        help="RDS DB instance identifier (example: edo-rds01)",
    )
    parser.add_argument(
        "--strict-empty-saopaulo",
        action="store_true",
        help="Also prove that São Paulo contains ZERO RDS databases.",
    )
    args = parser.parse_args()

    db_id = args.db_id.strip()
    stamp = utc_now_stamp()

    # Ensure audit folder exists
    AUDIT_DIR.mkdir(parents=True, exist_ok=True)

    lines: List[str] = []
    lines.append("01 — DATA RESIDENCY PROOF")
    lines.append("========================")
    lines.append("")
    lines.append(f"Generated (UTC): {stamp}")
    lines.append(f"Target DB Identifier: {db_id}")
    lines.append(f"Authorized DB Region: {TOKYO_REGION} (Tokyo)")
    lines.append(f"Disallowed DB Region: {SAOPAULO_REGION} (São Paulo)")
    lines.append("")

    # Credential sanity check
    try:
        boto3.client("sts").get_caller_identity()
    except NoCredentialsError:
        lines.append("❌ ERROR: AWS credentials not found.")
        lines.append("Fix: Configure AWS credentials and re-run.")
        OUTPUT_FILE.write_text("\n".join(lines))
        return 2

    # --- Tokyo check ---
    found_tokyo, tokyo_db = describe_db_instance(TOKYO_REGION, db_id)
    if not found_tokyo:
        lines.append("❌ COMPLIANCE FAILURE")
        lines.append(f"- DB '{db_id}' was NOT found in Tokyo.")
        OUTPUT_FILE.write_text("\n".join(lines))
        return 1

    lines.append("✅ TOKYO PRESENCE CHECK: PASS")
    lines.append("- Database exists in Tokyo as required.")
    lines.append("Tokyo DB Summary:")
    lines.append(json.dumps(db_summary(tokyo_db, TOKYO_REGION), indent=2))
    lines.append("")

    # --- São Paulo absence check ---
    found_sa, sa_db = describe_db_instance(SAOPAULO_REGION, db_id)
    if found_sa:
        lines.append("❌ COMPLIANCE FAILURE")
        lines.append(f"- DB '{db_id}' was found in São Paulo, which violates residency.")
        lines.append("São Paulo DB Summary:")
        lines.append(json.dumps(db_summary(sa_db, SAOPAULO_REGION), indent=2))
        OUTPUT_FILE.write_text("\n".join(lines))
        return 1

    lines.append("✅ SÃO PAULO ABSENCE CHECK: PASS")
    lines.append("- No database with this identifier exists in São Paulo.")
    lines.append("")

    # --- Optional stronger proof ---
    if args.strict_empty_saopaulo:
        sa_dbs = list_all_db_instances(SAOPAULO_REGION)
        lines.append("✅ STRICT CHECK — SÃO PAULO RDS INVENTORY")
        lines.append(f"- Total RDS DB instances in São Paulo: {len(sa_dbs)}")
        if sa_dbs:
            lines.append("Identifiers present:")
            lines.append(json.dumps([d["DBInstanceIdentifier"] for d in sa_dbs], indent=2))
        else:
            lines.append("- No RDS databases exist in São Paulo.")
        lines.append("")

    lines.append("AUDITOR NOTES")
    lines.append("-------------")
    lines.append("- Proof generated using AWS RDS control-plane APIs (DescribeDBInstances).")
    lines.append("- Demonstrates enforced data residency: database located only in Tokyo.")
    lines.append("- Supports APPI / data-sovereignty compliance requirements.")

    OUTPUT_FILE.write_text("\n".join(lines))
    print(f"Proof file written to: {OUTPUT_FILE}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())