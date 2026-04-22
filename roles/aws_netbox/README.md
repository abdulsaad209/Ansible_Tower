AWS-NETBOX
=========

Role name is **AWS-NETBOX**, It's basically use to sync AWS VPC, Instances and Subnet Details into Netbox. First it fetch data from AWS using amazon.aws modules and then sync that data into Netbox using netbox.netbox modules.

Requirements
------------


## Install and Configure AWS CLI with AWS Profiles.

```
### Install Python and Ansible
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
[c1prod]
aws_access_key_id = XYZ
aws_secret_access_key = ABC
```

```
vim ~/.aws/config
```
```
[profile c1prod]
region = us-west-2
output = json

[profile vpdev]
role_arn = arn:aws:iam::216207491940:role/AnsibleExecutionRole
source_profile = c1prod
region = us-east-1

[profile vpprod]
role_arn = arn:aws:iam::252208100104:role/AnsibleExecutionRole
source_profile = c1prod
region = us-east-1

[profile ldbvdev]
role_arn = arn:aws:iam::459763941502:role/AnsibleExecutionRole
source_profile = c1prod
region = us-west-2

[profile szssprod]
role_arn = arn:aws:iam::279153405224:role/AnsibleExecutionRole
source_profile = c1prod
region = us-west-2

[profile tpcaprod]
role_arn = arn:aws:iam::714364336841:role/AnsibleExecutionRole
source_profile = c1prod
region = us-east-1

[profile tpcastaging]
role_arn = arn:aws:iam::979741162430:role/AnsibleExecutionRole
source_profile = c1prod
region = us-east-1

[profile z5prod]
role_arn = arn:aws:iam::540997483535:role/AnsibleExecutionRole
source_profile = c1prod
region = us-east-1

[profile zpsddev]
role_arn = arn:aws:iam::116597800483:role/AnsibleExecutionRole
source_profile = c1prod
region = us-east-1

[profile zpsdprod]
role_arn = arn:aws:iam::066416945513:role/AnsibleExecutionRole
source_profile = c1prod
region = us-east-1

[profile zpcorpprod]
role_arn = arn:aws:iam::328462708690:role/AnsibleExecutionRole
source_profile = c1prod
region = us-east-1
```

### Make sure NetBox URL is resolving through DNS and you are able to access or curl it
```
curl http://netbox.hub.csiprod.com -I
```
### Install NetBox and AWS Collections
```
ansible-galaxy collection install netbox.netbox:3.22.0
ansible-galaxy collection install amazon.aws:11.2.0
```
**If you are using Ansible Tower then add these collection inside collections/requirements.yml**
```
---
collections:
  - name: netbox.netbox
    version: 3.22.0
  - name: amazon.aws
    version: 11.2.0
```

Role Variables
--------------

**Main Variables of This role are mentioned below, rest of the variables you can use default one as defined in defaults/main.yml.**

1. Netbox Related:
```
netbox_url: "<your netbox url>"
netbox_token: "<api token used to connect with netbox>"
```
**This will be used to run playbook for specific aws account or tag only**
```
target_accounts:
  - "all"
  - "<account name of aws, tags defined for tenant in netbox etc>"
```

**If netbox api calls failing the job then you can increase task retries or delay value from here**
- retries mean: task after fail will run 5 times more
- delay mean: each time will task retry to run, there would be gap of 10 seconds in each run
```
task_retries: 5
task_delay: 10
```
2. AWS Related

In this variable you can define multiple AWS Accounts which you wanna sync to NetBox
```
aws_accounts:
  - name: "VPMA-DEV-EXT-ACCOUNT"
    profile: "vpdev"  # AWS CLI profile name
    netbox_tenant: "VPMA-DEV-EXT-ACCOUNT"
    netbox_tenant_slug: "vpma-dev-ext-account"
    netbox_tags:
      - "VP"
      - "Dev"
    regions:
      - us-east-1

```

Dependencies
------------

There is no Dependency for now but if you wanna configure this playbook more dynamically or wanna add into CronJob then you can use and configure below Bash Script.

Directory Structure:
For Netbox Sync Script
```
/usr/local/tasks/Netbox/AWS-NETBOX-SYNC/
                    --- AWS-NETBOX
                    --- ansible.cfg
                    --- deployment.yml
                    --- inventory.yml
                    --- README.md
                    --- run_netbox_sync.sh

mkdir -p /usr/local/tasks/Netbox/AWS-NETBOX-SYNC

cp -R aws_netbox /usr/local/tasks/Netbox/AWS-NETBOX-SYNC/AWS-NETBOX

```
For Netbox Decommissioned VMs Removal
```
/usr/local/tasks/Netbox/AWS-NETBOX-DECOMMISSIONING/
                    --- REMOVE-VM
                    --- deployment.yml
                    --- inventory.yml
                    --- run_netbox_remove.sh


mkdir -p /usr/local/tasks/Netbox/AWS-NETBOX-DECOMMISSIONING/

cp -R aws_netbox/tasks/remove_netbox_vm.yml REMOVE-VM/tasks/main.yml

```
```
vim REMOVE-VM/defaults/main.yml

---
# defaults file for removevm
netbox_url: "{{ lookup('env', 'NETBOX_URL') }}"
netbox_token: "{{ lookup('env', 'NETBOX_TOKEN') }}"
```
```
vim run_netbox_remove.sh

#!/bin/bash

set -Eeuo pipefail


: << 'EOF'
------------------------------------------------------------------------------
NetBox Decommissioned VM Cleanup Script

This script runs the Ansible playbook to remove VMs
in "decommissioning" state from NetBox.

Usage:
  ./run_remove_vm.sh

No arguments required.

------------------------------------------------------------------------------
EOF

export PATH=$PATH:/usr/local/bin

LOG_FILE="/var/log/netbox_remove_vm.log"
LOCK_FILE="/var/run/netbox_remove_vm.lock"

BASE_DIR="/usr/local/tasks/Netbox/AWS-NETBOX-DECOMMISSIONING"

#################################
### Send EMAIL on job Failure ###
#################################

EMAIL="saad.zahid@zurple.com nadir.mehmood@constellation1.com abdul.quddos@z57.com"
HOSTNAME=$(hostname)

send_failure_email() {
    SUBJECT="NetBox decommissioned Removal FAILED on $HOSTNAME"

    {
        echo "NetBox VM Removal job FAILED"
        echo ""
        echo "Host: $HOSTNAME"
        echo "Time: $(date)"
        echo ""
        echo "Failed Command: $BASH_COMMAND"
        echo "Exit Code: $?"
        echo ""
        echo "===== Last 50 lines of log ====="
        tail -n 50 "$LOG_FILE"
    } | mail -s "$SUBJECT" $EMAIL
}

trap 'send_failure_email' ERR

#################################


cd "$BASE_DIR"
if [ -f /root/.netbox.env ]; then
    set -a
    source /root/.netbox.env
    set +a
else
    echo "[$(date)] ERROR: .env file not found" >> "$LOG_FILE"
    exit 1
fi


# Lock mechanism
exec 200>"$LOCK_FILE"
flock -n 200 || {
    echo "[$(date)] Another instance is already running. Exiting." >> "$LOG_FILE"
    exit 1
}

# Clear previous log
: > "$LOG_FILE"

echo "[$(date)] Starting NetBox VM cleanup job" | tee -a "$LOG_FILE"

# Run playbook
time ansible-playbook \
  -i inventory.yml \
  deployment.yml 2>&1 | tee -a "$LOG_FILE"

echo "[$(date)] Completed NetBox VM cleanup job" | tee -a "$LOG_FILE"


```

```
vim ansible.cfg

[defaults]
forks          = 1
poll_interval  = 15
content_sync_enabled = false
retry_files_enabled = True
error_on_undefined_vars = True
```

```
vim deployment.yml
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

```
vim inventory.yml
---
all:                                    # Top-level group containing all hosts
  hosts:                                # Defines the hosts in this group
    localhost:                          # The hostname/target machine
      ansible_connection: local         # How Ansible connects to this host
      ansible_python_interpreter: /bin/python3.11  # Which Python to use
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

BASE_DIR="/usr/local/tasks/Netbox/NETBOX-SYNC"
cd "$BASE_DIR"
if [ -f /root/.netbox.env ]; then
    set -a
    source /root/.netbox.env
    set +a
else
    echo "[$(date)] ERROR: .env file not found" >> "$LOG_FILE"
    exit 1
fi


LOG_FILE="/var/log/netbox_sync.log"

#################################
### Send EMAIL on job Failure ###
#################################

EMAIL="saad.zahid@zurple.com nadir.mehmood@constellation1.com abdul.quddos@z57.com"
HOSTNAME=$(hostname)

LOCK_FILE="/var/run/netbox_sync.lock"

INPUT="${1:-all}"

send_failure_email() {
    SUBJECT="NetBox Sync FAILED on $HOSTNAME"

    {
        echo "NetBox Sync job FAILED"
        echo ""
        echo "Host: $HOSTNAME"
        echo "Time: $(date)"
        echo "Input: $INPUT"
        echo ""
        echo "===== Last 50 lines of log ====="
        tail -n 50 "$LOG_FILE"
    } | mail -s "$SUBJECT" $EMAIL
}

trap 'send_failure_email' ERR

#################################

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
/usr/local/tasks/Netbox/run_netbox_sync.sh all

### Configure into CronJob
# To update the AWS Instances, VPC and Subnet Details in NetBox
0 7 * * * /usr/local/tasks/Netbox/NETBOX-SYNC/run_netbox_sync.sh all > /dev/null 2>&1

# job to remove decommissioning instances from NEtbox
0 6 * * 0 /usr/local/tasks/Netbox/AWS-NETBOX-DECOMMISSIONING/run_netbox_remove.sh > /dev/null 2>&1

```

Resources
------------------

https://galaxy.ansible.com/ui/repo/published/netbox/netbox/
https://galaxy.ansible.com/ui/repo/published/amazon/aws/?extIdCarryOver=true&sc_cid=RHCTG0180000371695&version=11.2.0
