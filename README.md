![image](https://github.com/user-attachments/assets/65cdf663-3537-4116-bb97-c52a0beefc5b)

# Ansible_Tower
**** Installation of Ansible Tower/AWX through Docker on ubuntu 22.04LTS *****

## If you are not able to use yum package manager then add base repo in repositories directory
sudo curl https://raw.githubusercontent.com/sdhmh/enable-centos-7-repo/main/CentOS-Base.repo --output /etc/yum.repos.d/CentOS-Base.repo

echo "Installation of Necessary Packages:"
yum install -y epel-release 
yum install -y git gcc gcc-c++ ansible nodejs gettext device-mapper-persistent-data lvm2 bzip2 python3-pip vim wget 

echo "Adding docker repo and installing docker package"
wget https://download.docker.com/linux/centos/docker-ce.repo --directory-prefix /etc/yum.repos.d/
echo "yum repolist"
echo "Installing Docker.............."
yum install docker-ce -y

echo "start and enable docker service"
systemctl enable --now docker
systemctl status docker

echo "install docker-compose module"
pip3 install -U pip setuptools 
pip3 install docker-compose 

echo "setup PATH for docker-compose"
export PATH=$PATH:/usr/local/bin
which docker-compose
ls /usr/local/bin/docker-compose

echo "Defining Alias for Docker Compose"
alias docker-compose=/usr/local/bin/docker-compose

echo "Take clone of ansible awx repo version 17.1.0"
git clone -b 17.1.0 https://github.com/ansible/awx.git

echo "generate random secret key"
cd awx
openssl rand -base64 30 > key.txt

cd installer/




**** Do changes in inventory file as per your need ****

vim inventory

localhost ansible_connection=local ansible_python_interpreter="/usr/bin/env python3"
[all:vars]
dockerhub_base=ansible
awx_task_hostname=awx
awx_web_hostname=awxweb
postgres_data_dir="/var/lib/awx/pgdocker"
host_port=80
host_port_ssl=443
docker_compose_dir="/var/lib/awx/pgdocker"  ## awx project db directory will mount locally
pg_username=awx
pg_password=awxpass
pg_database=awx
pg_port=5432
admin_user=admin
admin_password=admin123  # <your admin dashboard password>
create_preload_data=True
secret_key=Nl9+e7jISeYj69JMpOfeHqKEZgrvClKKc2aU7S0f  # paste the key.txt key here 
awx_alternate_dns_servers="8.8.8.8,8.8.4.4"
project_data_dir=/var/lib/awx/projects  ## awx project dir will mount locally

**** disable selinux before running script ****
** Before running docker container make sure SELINUX should be in disabled state. **

vim /etc/selinux/config
SELINUX=disabled

** Reboot the system **
If you perform any changes in SELINUX then need to reboot the system to implement the changes.
sudo reboot

** Add rule in firewalld service **
I am disabling the service for now you can perform changes as per your need

systemctl stop firewalld 
export PATH=$PATH:/usr/local/bin
systemctl restart docker
ansible-playbook -i ~/awx/installer/inventory ~/awx/installer/install.yaml

Note: If installation got failed then run again it will solve this time, if still face issue then you did something wrong do troubleshoot it.


************ Use of Ansible Vault ************

vim secrets.yaml
# secrets.yml
pg_password: 'awxpass'
admin_password: 'saad123'
secret_key: 'Nl9+e7jISeYj69JMpOfeHqKEZgrvClKKc2aU7S0f'

# Now encrypt the file with ansible vault 
ansible-vault encrypt secrets.yaml

# Create file to store vault password
vim vault_password.txt

# Add your vault password in it
2qZyw2aVA1W0tJsBmqe5

## assign permissions to file
chmod 600 vault_password.txt

## Now add your secrets.yaml path in the playbook
vim ~/awx/installer/install.yml

---
- name: Build and deploy AWX
  hosts: all
  vars_files:
    - "/root/secrets.yaml"




## Now run the playbook
ansible-playbook -i ~/awx/installer/inventory ~/awx/installer/install.yml --vault-password-file /root/awx/vault_password.txt

pg_password: 'awxpass'
admin_password: 'saad123'
secret_key: 'Nl9+e7jISeYj69JMpOfeHqKEZgrvClKKc2aU7S0f'
vault_password = 2qZyw2aVA1W0tJsBmqe5



## resources

docker using vfs file system
https://docs.docker.com/engine/storage/drivers/overlayfs-driver/


## to change admin password of dashboard
user: admin
sudo docker exec -it awx_task bash
awx-manage changepassword admin
