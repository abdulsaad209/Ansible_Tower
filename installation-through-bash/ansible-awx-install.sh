#!/bin/bash

set -e

# Ensure base repo is present
sudo curl -o /etc/yum.repos.d/CentOS-Base.repo https://raw.githubusercontent.com/sdhmh/enable-centos-7-repo/main/CentOS-Base.repo

# Install necessary packages
yum install -y epel-release git gcc gcc-c++ ansible nodejs gettext \
  device-mapper-persistent-data lvm2 bzip2 python3-pip vim wget

# Add Docker repository
wget https://download.docker.com/linux/centos/docker-ce.repo -P /etc/yum.repos.d/

# Install Docker
yum install -y docker-ce

# Start and enable Docker service
systemctl enable --now docker

# Install Docker Compose
pip3 install -U pip setuptools
pip3 install docker-compose

# Set up PATH for Docker Compose
echo 'export PATH=$PATH:/usr/local/bin' >> /etc/profile.d/docker-compose.sh
source /etc/profile.d/docker-compose.sh

# Clone AWX repository
git clone -b 17.1.0 https://github.com/ansible/awx.git /root/awx

# Generate secret key
openssl rand -base64 30 > /root/awx/key.txt

# Load secrets from an external vault file
source /root/secrets.env

# Configure AWX inventory file
cat > /root/awx/installer/inventory <<EOL
localhost ansible_connection=local ansible_python_interpreter="/usr/bin/env python3"

[all:vars]
dockerhub_base=ansible
awx_task_hostname=awx
awx_web_hostname=awxweb
postgres_data_dir="/var/lib/awx/pgdocker"
host_port=80
host_port_ssl=443
docker_compose_dir="/var/lib/awx/pgdocker"
pg_username=awx
pg_password=${PG_PASSWORD}
pg_database=awx
pg_port=5432
admin_user=admin
admin_password=${ADMIN_PASSWORD}
create_preload_data=True
secret_key=$(cat /root/awx/key.txt)
awx_alternate_dns_servers="8.8.8.8,8.8.4.4"
project_data_dir=/var/lib/awx/projects
EOL

# Disable SELinux
#sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
#
## Reboot system if SELinux was modified
#if [ $(getenforce) != "Disabled" ]; then
#  echo "Rebooting to apply SELinux changes"
#  reboot
#fi
#
## Stop firewalld
#systemctl stop firewalld
#systemctl disable firewalld

# Restart Docker
systemctl restart docker

# Run AWX installation playbook
echo "Running Job in Background"
echo "Run ps -aux | grep ansible"
echo "docker ps"
nohup ansible-playbook -i /root/awx/installer/inventory /root/awx/installer/install.yml --vault-password-file /root/vault_password.txt > /root/awx_install.log 2>&1 &
