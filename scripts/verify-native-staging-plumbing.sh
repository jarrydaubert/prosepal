#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

python3 - <<'PY'
from pathlib import Path
import json
import re
import sys
import xml.etree.ElementTree as ET

repo = Path.cwd()
project = repo / "prosepal-ios" / "ProsePal.xcodeproj"
shared_scheme = project / "xcshareddata" / "xcschemes" / "ProsePal.xcscheme"
local_scheme = project / "xcuserdata" / "jarrydaubert.xcuserdatad" / "xcschemes" / "ProsePal Local Staging.xcscheme"
storekit_file = repo / "prosepal-ios" / "App" / "ProsePalStaging.storekit"
pbxproj = project / "project.pbxproj"

expected_env_keys = [
    "PROSEPAL_GATEWAY_URL",
    "PROSEPAL_DEV_GATEWAY_SECRET",
    "PROSEPAL_SUPABASE_URL",
    "PROSEPAL_SUPABASE_ANON_KEY",
    "PROSEPAL_PREMIUM_PRODUCT_IDS",
    "PROSEPAL_RECOMMENDED_PREMIUM_PRODUCT_ID",
]
expected_products = {
    "com.prosepal.pro.yearly",
    "com.prosepal.pro.monthly",
    "com.prosepal.pro.weekly",
}

def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)

def parse_scheme(path: Path) -> ET.Element:
    if not path.exists():
        fail(f"missing scheme: {path}")
    try:
        return ET.parse(path).getroot()
    except ET.ParseError as error:
        fail(f"could not parse scheme XML: {path}: {error}")

def env_vars(root: ET.Element) -> dict[str, str]:
    return {
        item.get("key"): item.get("isEnabled", "UNKNOWN")
        for item in root.findall(".//EnvironmentVariable")
        if item.get("key")
    }

shared_root = parse_scheme(shared_scheme)
shared_prosepal_env = [
    key for key in env_vars(shared_root)
    if key.startswith("PROSEPAL_")
]
if shared_prosepal_env:
    fail("shared ProsePal scheme still contains PROSEPAL_* run environment keys")
print("shared_scheme=clean")

local_root = parse_scheme(local_scheme)
local_env = env_vars(local_root)
for key in expected_env_keys:
    if local_env.get(key) != "YES":
        fail(f"local staging scheme missing enabled key: {key}")
print(f"local_scheme_env_keys_enabled={len(expected_env_keys)}")

storekit_refs = []
for elem in local_root.iter():
    for attr, value in elem.attrib.items():
        if "storekit" in value.lower():
            resolved = (local_scheme.parent / value).resolve()
            storekit_refs.append(resolved)

if not storekit_refs:
    fail("local staging scheme has no StoreKit configuration reference")
if storekit_file.resolve() not in storekit_refs:
    fail("local staging scheme StoreKit reference does not resolve to App/ProsePalStaging.storekit")
print("local_scheme_storekit_reference=ok")

try:
    storekit = json.loads(storekit_file.read_text())
except json.JSONDecodeError as error:
    fail(f"invalid StoreKit JSON: {error}")

subscriptions = []
for group in storekit.get("subscriptionGroups", []):
    subscriptions.extend(group.get("subscriptions", []))
product_ids = {item.get("productID") for item in subscriptions if item.get("productID")}
missing = expected_products - product_ids
if missing:
    fail(f"StoreKit config missing expected product ids: {','.join(sorted(missing))}")
print(f"storekit_subscription_products={len(product_ids)}")

if pbxproj.exists():
    project_text = pbxproj.read_text()
    reference_count = len(re.findall(
        r"isa = PBXFileReference;[^}\n]+path = ProsePalStaging\.storekit;",
        project_text
    ))
    if reference_count != 1:
        fail(f"expected one project StoreKit file reference, saw {reference_count}")
    print("project_storekit_reference=single")
else:
    fail("missing project.pbxproj")

print("native_staging_plumbing=ok")
PY
