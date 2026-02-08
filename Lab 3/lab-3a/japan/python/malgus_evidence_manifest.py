#!/usr/bin/env python3
"""
malgus_evidence_manifest.py

Generates evidence.json for lab3-audit-pack.
This file acts as a machine-readable audit index of all proof artifacts.
"""

from datetime import datetime, timezone
from pathlib import Path
import json

AUDIT_DIR = Path(__file__).parent / "lab3-audit-pack"
OUTPUT_FILE = AUDIT_DIR / "evidence.json"


def utc_stamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def main():
    AUDIT_DIR.mkdir(parents=True, exist_ok=True)

    evidence_items = [
        {
            "id": "01",
            "name": "Data Residency Proof",
            "file": "01_data-residency-proof.txt",
            "controls": ["Data Residency", "APPI"],
            "description": "Proves application database exists only in Tokyo and not in São Paulo."
        },
        {
            "id": "02",
            "name": "Edge Proof (CloudFront)",
            "file": "02_edge-proof-cloudfront.txt",
            "controls": ["Edge Caching", "Global Delivery"],
            "description": "Explains CloudFront edge behavior and cache outcomes (Hit/Miss)."
        },
        {
            "id": "03",
            "name": "WAF Proof",
            "file": "03_waf-proof.txt",
            "controls": ["Web Application Firewall"],
            "description": "Summarizes WAF ALLOW vs BLOCK decisions from CloudWatch Logs."
        },
        {
            "id": "04",
            "name": "CloudTrail Change Proof",
            "file": "04_cloudtrail-change-proof.txt",
            "controls": ["Change Management", "Audit Logging"],
            "description": "Shows who changed what using CloudTrail Event History."
        },
        {
            "id": "05",
            "name": "Network Corridor Proof",
            "file": "05_network-corridor-proof.txt",
            "controls": ["Network Segmentation", "TGW Corridor"],
            "description": "Proves controlled TGW routing between Tokyo and São Paulo."
        },
    ]

    # Mark which files actually exist
    for item in evidence_items:
        item["exists"] = (AUDIT_DIR / item["file"]).exists()

    manifest = {
        "audit_pack": "lab3-audit-pack",
        "generated_utc": utc_stamp(),
        "evidence_count": len(evidence_items),
        "evidence": evidence_items,
    }

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)

    print(f"Evidence manifest written to: {OUTPUT_FILE}")


if __name__ == "__main__":
    main()