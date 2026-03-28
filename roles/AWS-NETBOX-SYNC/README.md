### Cron Job Configuration

crontab -e

0 19 * * * /usr/local/tasks/Netbox/run_netbox_sync.sh all >> /var/log/cron_netbox.log 2>&1

mkdir -p /usr/local/tasks/Netbox


vim /usr/local/tasks/Netbox/run_netbox_sync.sh

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

BASE_DIR="/usr/local/tasks/Netbox/AWS-NETBOX-SYNC"
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





Another version 

```
#!/bin/bash

set -euo pipefail

export PATH=$PATH:/usr/local/bin

BASE_DIR="/usr/local/tasks/Netbox/AWS-NETBOX-SYNC"
cd "$BASE_DIR"

LOG_FILE="/var/log/netbox_sync.log"
LOCK_FILE="/var/run/netbox_sync.lock"

INPUT="${1:-all}"

# 🔒 Lock
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
ansible-playbook \
  -i inventory.yml \
  -e "{\"target_accounts\": $TARGET_JSON}" \
  deployment.yml 2>&1 | tee -a "$LOG_FILE"

echo "[$(date)] Completed NetBox sync for: $INPUT" | tee -a "$LOG_FILE"
```

chmod +x /usr/local/tasks/Netbox/run_netbox_sync.sh

cp -R /root/Ansible_Tower/roles/AWS-NETBOX-SYNC /usr/local/tasks/Netbox/AWS-NETBOX-SYNC


Prerequisites to Run Netbox-Update-Playbook

### Step1: Install Required Packages

sudo dnf update -y
sudo dnf install -y epel-release
dnf install python3.11 -y

sudo dnf install python3.11 python3.11-pip -y
pip3.11 install boto3 botocore pynetbox ansible-core==2.17.0


ln -s /usr/local/bin/ansible /bin/ansible


### Install AWS CLI ###
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install


############# Versions Detail ##############
Ansible Version: ansible [core 2.17.0]
Python Version: Python 3.11.13
AWS CLI Version: aws-cli/2.34.11

amazon.aws Version: "11.2.0"
netbox.netbox Version: "3.22.0"
############################################


### Step2: Configure AWS Profiles

vim ~/.aws/credentials
[c1prod]
aws_access_key_id = XYZ
aws_secret_access_key = XYZ 


vim ~/.aws/config
[profile c1prod]
region = us-west-2

[profile vpdev]
role_arn = arn:aws:iam::216207491940:role/AnsibleExecutionRole
source_profile = c1prod
region = us-east-1

[profile vpprod]
role_arn = arn:aws:iam::252208100104:role/AnsibleExecutionRole
source_profile = c1prod
region = us-east-1


### Step3: Make sure NetBox URL is resolving through DNS and you are able to access or curl it 
curl http://netbox.hub.csiprod.com -I


### Step4: Add Required Policy in AWS IAM Role 
Add ec2:DescribeVpcClassicLink Policy in vpdev, vpprod and c1prod IAM Roles

arn:aws:iam::216207491940:role/AnsibleExecutionRole
arn:aws:iam::252208100104:role/AnsibleExecutionRole

### Step4: Install Netbox and AWS Collections
ansible-galaxy collection install netbox.netbox:3.22.0
ansible-galaxy collection install amazon.aws:11.2.0



Resources: 
https://galaxy.ansible.com/ui/repo/published/netbox/netbox/
https://galaxy.ansible.com/ui/repo/published/amazon/aws/?extIdCarryOver=true&sc_cid=RHCTG0180000371695&version=11.2.0

