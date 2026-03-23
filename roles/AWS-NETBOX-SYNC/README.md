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

