ZABBIX-AGENT2
------------

This is **ZABBIX-AGENT2** role designed to run only for Servers which is **compatible with zabbix-agent2**, This role will use to install, configure zabbix-agent2. By using this role you can also define separate custom param used in the configuration to monitor extra processes as defined in the variables section.

Requirements
------------

No requirements. You can run this on both Windows and Linux Servers.

Role Variables
--------------

You can define custom UserParam values like below

### Example:

```
zabbix_custom_userparams:
    disk_check: |
      UserParameter=disk.free,/usr/bin/df -h / | tail -1 | awk '{print $4}'
    nginx_status: |
      UserParameter=nginx.active_connections,curl -s http://127.0.0.1/nginx_status | grep 'Active' | awk '{print $3}'
```

You can configure as many Extra UserParam as you wanna configure, for each separate variable like disk_check, nginx_status it will create separate files in under /etc/zabbix/zabbix_agent2.d/ directory with .conf extension. 
For example:
here i am defining disk_check as extra variable to store userparam related to disk so it will create a file.

```
/etc/zabbix/zabbix_agent2.d/disk_check.conf
```
 and will store the content in this file like this.

 ```
 UserParameter=disk.free,/usr/bin/df -h / | tail -1 | awk '{print $4}'
 ```

Dependencies
------------

No Dependencies

Example Playbook
----------------

```
---
- name: Deploy Zabbix Agent2
  hosts: all
  vars:
    zabbix_custom_userparams:
      disk_check: |
        UserParameter=disk.free,/usr/bin/df -h / | tail -1 | awk '{print $4}'
      nginx_status: |
        UserParameter=nginx.active_connections,curl -s http://127.0.0.1/nginx_status | grep 'Active' | awk '{print $3}'
  
  roles:
    - ZABBIX-AGENT2
```

License
-------


Author Information
------------------

This role is created by Saad Zahid, you can reach out to me here.
Email: saadzahid248@gmail.com, saad.zahid@zurple.com