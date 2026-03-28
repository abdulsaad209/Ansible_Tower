#!/bin/bash

set -euo pipefail

: << 'EOF'
------------------------------------------------------------------------------
Without Extra Arg By Default Script run for All AWS Accounts
./run_netbox_sync.sh

List of AWS Accounts Name with Tags
   Account-Name:          Tags List

1. VPMA-DEV-EXT-ACCOUNT:  ['VP','Dev']
2. VPMA-PROD-EXT-ACCOUNT: ['VP','Prod']
3. C1US-PROD-EXT-ACCOUNT: ['C1','Prod']


---------------------------------------------------------------------------------------------
# DISCLAIMER:
# This script supports both account-based and tag-based execution.
#
# 1. Account-based execution:
#    - Provide the AWS account name to target a specific account or list of multiple accounts.
#    - Single Account Example: ./run-script.sh VPMA-DEV-EXT-ACCOUNT
#    - Multi Account Example: ./run-script.sh VPMA-DEV-EXT-ACCOUNT,VPMA-PROD-EXT-ACCOUNT
#    - Best to pass as xtraarg if you wanna run for speficific AWS Account
#
# 2. Tag-based execution:
#    - Provide tags (comma-separated) to filter accounts.
#    - Example: ./run-script.sh VP,Dev
#    - The script will run for ALL accounts matching ANY of the provided tags.
#    - Best to pass as xtraarg if you wanna run for specific environments like Prod,AWS,VP,C1
#
# Predefined tag mappings:
#   - VPMA-DEV-EXT-ACCOUNT   -> ['VP', 'Dev']
#   - VPMA-PROD-EXT-ACCOUNT  -> ['VP', 'Prod']
#   - C1US-PROD-EXT-ACCOUNT  -> ['C1', 'Prod']
#
# Important:
#   - Tags are used as filters, not exact account identifiers.
#   - Multiple accounts may be selected if they share the same tag.
#   - Always verify inputs before execution.
---------------------------------------------------------------------------------------------
EOF


export PATH=$PATH:/usr/local/bin

BASE_DIR="$(pwd)/AWS-NETBOX-SZCODERS"

cd "$BASE_DIR"

LOG_FILE="/var/log/netbox_sync.log"
LOCK_FILE="/var/run/netbox_sync.lock"

INPUT="${1:-all}"

# Lock
exec 200>"$LOCK_FILE"
flock -n 200 || {
    echo "[$(date)] Another instance is already running. Exiting." >> "$LOG_FILE"
    exit 1
}

: > "$LOG_FILE"

echo "[$(date)] Starting NetBox sync for: $INPUT" | tee -a "$LOG_FILE"

# Convert input to JSON array
if [[ "$INPUT" == "all" ]]; then
    TARGET_JSON="all"
else
    IFS=',' read -ra ACCOUNTS <<< "$INPUT"

    JSON_ARRAY=$(printf '"%s",' "${ACCOUNTS[@]}")
    JSON_ARRAY="[${JSON_ARRAY%,}]"
    TARGET_JSON="$JSON_ARRAY"
fi

# Run playbook
time ansible-playbook \
  -i inventory.yml \
  -e "{\"target_accounts\": $TARGET_JSON}" \
  deployment.yml 2>&1 | tee -a "$LOG_FILE"

echo "[$(date)] Completed NetBox sync for: $INPUT" | tee -a "$LOG_FILE"
