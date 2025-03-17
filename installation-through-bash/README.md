## Before running the script make sure you have implemented below steps

#### Step 1. Define your credentials of database and admin page in separate file

vim /root/secrets.env

PG_PASSWORD='your db custom password'

ADMIN_PASSWORD='your db custom admin password'

#### Step 2. Encrypt your credentials with Ansible Vault and store encrypted password in separate file to decrypt while running playbook

*** store vault password ***

vim /root/vault_password.txt

'paste your vault password here which you will use to encrypt the credentials'

*** encrypt the credentials ***

ansible-vault encrypt /root/secrets.env

enter your vault passsword stored in /root/vault_password.txt

#### Step 3. Disable SELINUX and Firewall

Your SELINUX should be disabled if its running

vim /etc/selinux/config

SELINUX=disabled

*** If you change value of SELINUX in selinux configuration file then you need to reboot the system to make effect of changes ***
reboot

*** Stop local firewall or allow necessary traffic rule in it ***

systemctl stop firewalls

systemctl disable firewalld

Now you can run the bash script

Note: If after running script job get's failed then run below command again
ansible-playbook -i /root/awx/installer/inventory /root/awx/installer/install.yml --vault-password-file /root/vault_password.txt





