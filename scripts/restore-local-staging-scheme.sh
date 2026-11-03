#!/bin/bash
# Restore the ignored local Xcode staging scheme from the user's backup copy.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP="${PROSEPAL_STAGING_SCHEME_BACKUP:-$HOME/.config/prosepal/xcode-schemes/ProsePal Local Staging.xcscheme}"
DEST="$REPO_ROOT/prosepal-ios/ProsePal.xcodeproj/xcuserdata/$USER.xcuserdatad/xcschemes/ProsePal Local Staging.xcscheme"
MANAGEMENT="$REPO_ROOT/prosepal-ios/ProsePal.xcodeproj/xcuserdata/$USER.xcuserdatad/xcschemes/xcschememanagement.plist"

if [[ ! -f "$BACKUP" ]]; then
  cat >&2 <<EOF
Missing staging scheme backup:
  $BACKUP

Create it from Xcode after configuring the ProsePal Local Staging scheme:
  mkdir -p ~/.config/prosepal/xcode-schemes
  cp "prosepal-ios/ProsePal.xcodeproj/xcuserdata/$USER.xcuserdatad/xcschemes/ProsePal Local Staging.xcscheme" ~/.config/prosepal/xcode-schemes/
  chmod 600 ~/.config/prosepal/xcode-schemes/"ProsePal Local Staging.xcscheme"
EOF
  exit 1
fi

mkdir -p "$(dirname "$DEST")"
cp "$BACKUP" "$DEST"
chmod 600 "$DEST"

python3 - "$DEST" <<'PY'
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

scheme = Path(sys.argv[1])
tree = ET.parse(scheme)
root = tree.getroot()

for item in root.findall(".//BuildableReference"):
    item.set("BlueprintIdentifier", "PP0000000000000000000048")
    item.set("BuildableName", "ProsePal Staging.app")
    item.set("BlueprintName", "ProsePal Staging")

storekit_references = root.findall(".//StoreKitConfigurationFileReference")
if len(storekit_references) != 1:
    print("Expected exactly one StoreKit configuration reference.", file=sys.stderr)
    sys.exit(1)
storekit_references[0].set("identifier", "../../App/ProsePalStaging.storekit")

tree.write(scheme, encoding="UTF-8", xml_declaration=True)
PY

if [[ -f "$MANAGEMENT" ]]; then
  /usr/libexec/PlistBuddy \
    -c 'Add :SchemeUserState:"ProsePal Local Staging.xcscheme" dict' \
    -c 'Add :SchemeUserState:"ProsePal Local Staging.xcscheme":orderHint integer 1' \
    "$MANAGEMENT" >/dev/null 2>&1 || true
fi

if ! git -C "$REPO_ROOT" check-ignore -q "$DEST"; then
  echo "Restored scheme is not ignored by Git; refusing to continue." >&2
  echo "$DEST" >&2
  exit 1
fi

python3 - "$DEST" <<'PY'
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

scheme = Path(sys.argv[1])
expected = [
    "PROSEPAL_GATEWAY_URL",
    "PROSEPAL_DEV_GATEWAY_SECRET",
    "PROSEPAL_SUPABASE_URL",
    "PROSEPAL_SUPABASE_ANON_KEY",
    "PROSEPAL_PREMIUM_PRODUCT_IDS",
    "PROSEPAL_RECOMMENDED_PREMIUM_PRODUCT_ID",
]

root = ET.parse(scheme).getroot()
enabled = {
    item.get("key")
    for item in root.findall(".//EnvironmentVariable")
    if item.get("key") and item.get("isEnabled") == "YES"
}

missing = [key for key in expected if key not in enabled]
values = {
    item.get("key"): (item.get("value") or "").strip()
    for item in root.findall(".//EnvironmentVariable")
    if item.get("key")
}
publishable_key = values.get("PROSEPAL_SUPABASE_ANON_KEY", "")
valid_publishable_key = (
    publishable_key.startswith("sb_publishable_")
    and len(publishable_key) > len("sb_publishable_")
) or (
    publishable_key.startswith("eyJ")
    and len(publishable_key.split(".")) == 3
    and all(publishable_key.split("."))
)
storekit_references = root.findall(".//StoreKitConfigurationFileReference")
storekit_identifier = (
    storekit_references[0].get("identifier")
    if len(storekit_references) == 1
    else None
)

if missing:
    print("Restored scheme is missing enabled keys:", ", ".join(missing), file=sys.stderr)
    sys.exit(1)
if not valid_publishable_key:
    print("Restored scheme has an invalid Supabase publishable/anon key.", file=sys.stderr)
    sys.exit(1)
if storekit_identifier != "../../App/ProsePalStaging.storekit":
    print("Restored scheme has an invalid StoreKit configuration reference.", file=sys.stderr)
    sys.exit(1)

targets_staging = all(
    item.get("BlueprintIdentifier") == "PP0000000000000000000048"
    and item.get("BuildableName") == "ProsePal Staging.app"
    and item.get("BlueprintName") == "ProsePal Staging"
    for item in root.findall(".//BuildableReference")
)
if not targets_staging:
    print("Restored scheme does not target ProsePal Staging.", file=sys.stderr)
    sys.exit(1)
PY

echo "Restored ProsePal Local Staging scheme from backup."
echo "Verified: expected env keys are enabled, StoreKit reference exists, scheme targets ProsePal Staging, and scheme is ignored by Git."

if pgrep -x Xcode >/dev/null 2>&1; then
  echo "Xcode is currently running and may have cached the previous scheme environment."
  echo "Quit Xcode completely, reopen the project, then run ProsePal Local Staging."
fi
