# Role Name
=========

Role name is zabbix-ui

# Requirements
------------

You should have installed below requirements in your execution environment to run this role.
By following below steps you can create custom execution env to run this role.
### Create Docker image
vim Dockerfile
```
FROM quay.io/ansible/awx-ee:24.6.0

USER root

# Install sudo and configure passwordless sudo for UID 1000
RUN yum install -y sudo && \
    useradd -u 1000 awx || true && \
    echo 'awx ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/awx && \
    chmod 440 /etc/sudoers.d/awx

# Install Python packages
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --upgrade pip && \
    pip3 install -r /tmp/requirements.txt

# Install Ansible collections to system path
COPY requirements.yml /tmp/requirements.yml
RUN ansible-galaxy collection install -r /tmp/requirements.yml -p /usr/share/ansible/collections

# Fix permissions for /runner directory
RUN mkdir -p /runner/requirements_collections && \
    chown -R 1000:1000 /runner

USER 1000
```

vim requirements.txt
```
zabbix-api
requests
```

vim requirements.yml
```
---
collections:
  - name: community.zabbix
    version: 4.0.0
  - name: community.mysql
```

### Build and push image to use in Ansible AWX
docker build -t saadzahid/zabbix-ui:v1 .
docker push saadzahid/zabbix-ui:v1

# Role Variables
--------------
Default Variables stored in roles/zabbix-ui/defaults/main.yml You can configured accordingly or can overwrite value by providing extra vars inside roles/zabbix-ui/vars/main.yml Or inside the Playbook.
The values defined inside defaults/main.yml explained below
--- 
zabbix_url: "Defined url of your zabbix dashboard for example https://zabbix.ms.com/zabbix or you can define IP, whatever your URL is doesn't matter."
zabbix_user: "Username of your zabbix dashboard which will help ansible to login on UI through API. You can provide value by hardcoding in the code or best practice is to provide through ansible vault or through ansible awx credentials."
zabbix_pass: "Define you password of zabbix username which will use to login to zabbix through API."

### Host details
host_name: "Provide hostname of your agent which you wanna add on zabbix ui, or you can go with default value which will automatically pick hostname on which host playbooks is running by variable {{ inventory_hostname }}"
visible_name: "Same like host_name {{ inventory_hostname }}"
host_ip: "Provide IP of your zabbix agent host which you wanna add on zabbix ui or just provide variable to automatically pick from inventory {{ ansible_host }}"
group_name: "These are groups value which you wanna attach with your host on zabbix ui i have set by default one if you wanna provide more than one group then provide value like below in list format."


template_name: "Same like group_name examples are below for providing multiple values.Kubernetes Kubelet by HTTP"
zabbix_groups:
  - "szcoders-corp"
  - "Linux servers"
  - "Proxy Servers"

zabbix_templates:
  - "Linux by Zabbix agent"
  - "ICMP Ping"


### Proxy details
proxy_name: "Provide name of your proxy by which you wanna add on zabbix ui default value will be {{ inventory_hostname }}"
proxy_ip: "Ip of your zabbix proxy, default value is {{ ansible_host }}"
proxy_mode: Defing proxy mode whether it should be active or passive e.g. # 0 = active, 1 = passive default value is 1 (active)
proxy_port: " provide port of your zabbix proxy, default is 10051"
proxy_hosts: []          # optional, list of host IDs to assign
proxy_id: Provide value of your zabbix proxy on zabbix ui you can get this by clicking on zabbix proxy on ui and then check id from url  showing in browser, 7
monitored_by: How you wanna monitor through proxy or server e.g. # 0 = Zabbix Server, 1 = Zabbix Proxy default value is 0
zabbix_proxy:   # Set to true if monitored via Zabbix Proxy if wanna monitor through zabbix server then set to false, default value is false


Dependencies
------------

A list of other roles hosted on Galaxy should go here, plus any details in regards to parameters that may need to be set for other roles, or variables that are used from other roles.

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

---
- name: Deploy Zabbix Agent
  hosts: corp
  become: true

  vars:
    zabbix_proxy: true    # Set to true if monitored via Zabbix Proxy
    monitored_by: 1        # 0 = Zabbix Server, 1 = Zabbix Proxy

  pre_tasks:

    - name: Dynamically set zabbix_server based on zabbix_proxy flag
      set_fact:
        zabbix_server: "{{ '10.0.0.37' if zabbix_proxy else '10.0.0.36' }}"

    - debug:
        msg: "Using Zabbix Server: {{ zabbix_server }} (proxy mode = {{ zabbix_proxy }})"

  roles:
    - zabbix-agent
    - zabbix-ui



License
-------

BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
