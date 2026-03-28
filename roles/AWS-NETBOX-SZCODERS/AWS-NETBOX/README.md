Role Name
=========

Role name is **AWS-NETBOX**, It's basically use to sync AWS VPC, Instances and Subnets Details into Netbox. First it fetch data from AWS using amazon.aws modules and then sync that data into Netbox using netbox.netbox modules.

Requirements
------------

For running this playbook you have to full-fill the below requirements.

1. Install and Configure AWS CLI with AWS Profiles.
2. Install Required Packages and Modules.

## Install and Configure AWS CLI with AWS Profiles.

```
### Install Python and utilities
sudo dnf update -y
sudo dnf install -y epel-release
dnf install python3.11 -y

sudo dnf install python3.11 python3.11-pip -y
pip3.11 install boto3 botocore pynetbox ansible-core==2.17.0
```

```
vim ~/.bashrc
```
```
export PATH=$PATH:/usr/local/bin
```

### Install AWS CLI
```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### Version Details
```
Ansible Version: ansible [core 2.17.0]
Python Version: Python 3.11.13
AWS CLI Version: aws-cli/2.34.11

amazon.aws Version: "11.2.0"
netbox.netbox Version: "3.22.0"
```

### Configure AWS Credentials and Profiles

```
vim ~/.aws/credentials
```

```
[szcoders-corp]
aws_access_key_id = XYZ
aws_secret_access_key = ABC
```

```
vim ~/.aws/config
```
```
[profile szcoders-corp]
region = us-east-1
output = json

[profile szcoders-prod]
role_arn = arn:aws:iam::744308405931:role/NetBoxSyncRole
source_profile = szcoders-corp
region = us-east-1
```

### Make sure NetBox URL is resolving through DNS and you are able to access or curl it 
```
curl http://netbox.ms.com -I
```
### Install NetBox and AWS Collections
```
ansible-galaxy collection install netbox.netbox:3.22.0
ansible-galaxy collection install amazon.aws:11.2.0
```

Role Variables
--------------

Main Variables of This role are mentioned below, rest of the variables you can use default one as defined in defaults/main.yml.

1. Netbox Related:
```
netbox_url: "<your netbox url>"
netbox_token: "<api token used to connect with netbox>"
```
This will be used to run playbook for specific aws account or tag only
```
target_accounts:
  - "all" 
  - "<account name of aws, tags defined for tenant in netbox etc>"
```

If netbox api calls failing the job then you can increase task retries or delay value from here
retries mean: task after fail will run 5 times more
delay mean: each time will task retry to run there would be gap of 10 seconds in each run
```
task_retries: 5
task_delay: 10
```
2. AWS Related

In the variable you can define multiple AWS Accounts which you wanna sync to NetBox
```
aws_accounts:
  - name: "SZCODERS-CORP-EXT-ACCOUNT"
    profile: "szcoders-corp"  # AWS CLI profile name
    netbox_tenant: "SZCODERS-CORP-EXT-ACCOUNT" # using this name tenent will be create in NetBox
    netbox_tenant_slug: "szcoders-corp-ext-account"
    netbox_tags:
      - "szcoders"
      - "Corp"
      - "AWS"
    regions:
      - us-east-1
```

Dependencies
------------

There is no Dependency for now but if you wanna configure this playbook more dynamically or wanna add into CronJob then you can use and configure below Bash Script.

Directory Structure:
```
/usr/local/tasks/Netbox/AWS-NETBOX-SZCODERS/
                    --- AWS-NETBOX
                    --- ansible.cfg
                    --- deployment.yml
                    --- inventory.yml
                    --- README.md
                    --- run_netbox_sync.sh
```
```
vim run_netbox_sync.sh
```
```
#!/bin/bash

set -euo pipefail

: << 'EOF'
------------------------------------------------------------------------------
Without Extra Arg By Default Script run for All AWS Accounts
./run_netbox_sync.sh

List of AWS Accounts Name with Tags
   Account-Name:          Tags List

1. SZCODERS-CORP-EXT-ACCOUNT:  ['szcoders','Corp']
2. SZCODERS-PROD-EXT-ACCOUNT: ['szcoders','Prod']

---------------------------------------------------------------------------------------------
# DISCLAIMER:
# This script supports both account-based and tag-based execution.
#
# 1. Account-based execution:
#    - Provide the AWS account name to target a specific account or list of multiple accounts.
#    - Single Account Example: ./run_netbox_sync.sh SZCODERS-CORP-EXT-ACCOUNT
#    - Multi Account Example: ./run_netbox_sync.sh SZCODERS-CORP-EXT-ACCOUNT,SZCODERS-PROD-EXT-ACCOUNT
#    - Best to pass as xtraarg if you wanna run for speficific AWS Account
#
# 2. Tag-based execution:
#    - Provide tags (comma-separated) to filter accounts.
#    - Example: ./run_netbox_sync.sh szcoders,Corp
#    - The script will run for ALL accounts matching ANY of the provided tags.
#    - Best to pass as xtraarg if you wanna run for specific environments like Prod,AWS,VP,Corp
#
# Important:
#   - Tags are used as filters, not exact account identifiers.
#   - Multiple accounts may be selected if they share the same tag.
#   - Always verify inputs before execution.
---------------------------------------------------------------------------------------------
EOF


export PATH=$PATH:/usr/local/bin

BASE_DIR="/usr/local/tasks/Netbox/AWS-NETBOX-SZCODERS"

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
```

```
chmod +x run_netbox_sync.sh
```

Example Playbook
----------------

1. If you wanna run Ansible Playbook Directly then below is Sample Run.

```
---
- name: Collect AWS Region Information
  hosts: localhost
  connection: local
  gather_facts: false

  vars:
    # Target Accounts to sync (by name or tag). Use "all" to sync all accounts.
    target_accounts:
      - "all"

  roles:
    - AWS-NETBOX
```
Example Run:

```
ansible-playbook -i inventory.yml -e "{\"target_accounts\": all}" deployment.yml
```

By default playbook will run for All Accounts but you can pass specific Account name or tag where you wanna run using **-e "{\"target_accounts\": <account name>}"** variable

2. Run through Bash (Easy to use, best for cronjob)
Make sure you follow the Correct Directory Structure as mentioned above. 

```
/usr/local/tasks/Netbox/AWS-NETBOX-SZCODERS/run_netbox_sync.sh all

### Configure into CronJob
0 19 * * * /usr/local/tasks/Netbox/AWS-NETBOX-SZCODERS/run_netbox_sync.sh all > /var/log/cron_netbox.log 2>&1
```

Author Information
------------------

This Role is Created by Saad Zahid. 
You can reach out me at saadzahid248@gmail.com

Resources
------------------

https://galaxy.ansible.com/ui/repo/published/netbox/netbox/
https://galaxy.ansible.com/ui/repo/published/amazon/aws/?extIdCarryOver=true&sc_cid=RHCTG0180000371695&version=11.2.0
