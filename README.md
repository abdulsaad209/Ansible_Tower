## You can Install Ansible Tower through Bash as well. 
Please check the [Bash Script](https://github.com/abdulsaad209/Ansible_Tower/tree/master/installation-through-bash).

## For Installing Latest Version of AWX 24.6.0 on Kubernetes Cluster Follow [This](https://github.com/abdulsaad209/Ansible_Tower/tree/master/installation-on-k8s-cluster) Guide

![image](https://github.com/user-attachments/assets/f2c957b9-d1cf-4fcd-a866-4947c2b12d19)

![image](https://github.com/user-attachments/assets/c8dc1bdd-f4dd-47fc-9d47-df031eee529c)



# Ansible_Tower
### Installation of Ansible Tower/AWX 17.1.0 through Docker on CentOS/RedHat 7 ###

If you are not able to use yum package manager then add base repo in repositories directory
```
sudo curl https://raw.githubusercontent.com/sdhmh/enable-centos-7-repo/main/CentOS-Base.repo --output /etc/yum.repos.d/CentOS-Base.repo
```
Installation of Necessary Packages:
```
yum install -y epel-release
yum install -y git gcc gcc-c++ ansible nodejs gettext device-mapper-persistent-data lvm2 bzip2 python3-pip vim wget 
```
Adding docker repo and installing docker package
```
wget https://download.docker.com/linux/centos/docker-ce.repo --directory-prefix /etc/yum.repos.d/
yum repolist
echo "Installing Docker.............."
yum install docker-ce -y
```
Start and enable docker service
```
systemctl enable --now docker
systemctl status docker
```
Install docker-compose module
```
pip3 install -U pip setuptools 
pip3 install docker-compose
```
Setup PATH for docker-compose
```
export PATH=$PATH:/usr/local/bin
which docker-compose
ls /usr/local/bin/docker-compose
```
Defining Alias for Docker Compose
```
alias docker-compose=/usr/local/bin/docker-compose
```

### Installing Ansible AWX 17.1.0
Take clone of ansible awx repo version 17.1.0"
```
git clone -b 17.1.0 https://github.com/ansible/awx.git
```
Generate random secret key
```
cd awx

openssl rand -base64 30 > key.txt

cd installer/
```
#### _Do changes in inventory file as per your need_

vim inventory
```
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
```

Before running docker container make sure SELINUX should be in disabled state.

vim /etc/selinux/config
```
SELINUX=disabled
```

Reboot the system

If you perform any changes in SELINUX then need to reboot the system to implement the changes.
```
sudo reboot
```

Add rule in firewalld service
I am disabling the service for now you can perform changes as per your need

```
systemctl stop firewalld 

export PATH=$PATH:/usr/local/bin

systemctl restart docker

ansible-playbook -i ~/awx/installer/inventory ~/awx/installer/install.yaml
```

If installation got failed then run again it will solve this time, if still face issue then you did something wrong do troubleshoot it.



### Use of Ansible Vault

vim secrets.yaml
```
pg_password: 'awxpass'

admin_password: 'saad123'

secret_key: 'Nl9+e7jISeYj69JMpOfeHqKEZgrvClKKc2aU7S0f'
```

Now encrypt the file with ansible vault 
```

ansible-vault encrypt secrets.yaml
```

Create file to store vault password
```
vim vault_password.txt
```
Add your vault password in it
```
<paste your vault password in the file>
```

Assign permissions to file
```
chmod 600 vault_password.txt
```

Now add your secrets.yaml path in the playbook

vim ~/awx/installer/install.yml
```
---

- name: Build and deploy AWX

  hosts: all
  
  vars_files:
  
    - "/root/secrets.yaml"
```

Now run the playbook
```
ansible-playbook -i ~/awx/installer/inventory ~/awx/installer/install.yml --vault-password-file /root/awx/vault_password.txt
```
```
pg_password: 'awxpass'

admin_password: 'saad123'

secret_key: 'Nl9+e7jISeYj69JMpOfeHqKEZgrvClKKc2aU7S0f'

vault_password = 2qZyw2aVA1W0tJsBmqe5
```


Resources

docker using vfs file system
```
https://docs.docker.com/engine/storage/drivers/overlayfs-driver/
```


To change admin password of dashboard
```
user: admin

sudo docker exec -it awx_task bash

awx-manage changepassword admin
```
