### 1. Purpose

These role containing following rules makes possible automated configuration of objects and policies in CheckPoint MDS per Domain (CMA):
- Groups
- Networks and services
- Packages
- Rules
- Gateways
- etc. 

Following CheckPoint Ansible modules are used:
https://galaxy.ansible.com/check_point/mgmt

The modules (and therefore this role) are idempotent which is great! 

Modules are documented in: 
https://docs.ansible.com/ansible/latest/modules/list_of_network_modules.html#check-point


### 2. Requirements
- Ansible 2.9+
- Python 2.7+
- Install modules:
- https://galaxy.ansible.com/check_point/mgmt


### 3. Input data
3.1 Ansible inventory containing CMAs data and access data:
```bash
 ans_inventory/mgmt_automation_inventory.yml
```

3.2 Objects, policy packages and rules per CMA: 
```bash
 defaults/
```

### 4. How to run the playbooks

4.1 Put MDS CMAs data and access data into inventory:
```bash
 ans_inventory/mgmt_automation_inventory.yml
```

4.2 Put your objects and policies data per CMA into: 
```bash
 roles/configureMgmt/defaults
```

4.3 Put the MDS IP and CMA names into /etc/hosts in format: 

```bash
<MDS_IP> <CMA_Name>
```

E.g.: 
```bash
192.168.168.10  CMA1
192.168.168.10  CMA2
```

4.4 Run the role via playbook by:
```bash
 ansible-playbook -i ans_inventory/mgmt_automation_inventory.yml playbooks/configure_mds_rules_objects.yml -v
```


### Optional ###

### 5. To get started 
To get started with the automation you might want to test a very simple playbook in:
```bash
 playbooks/mgmt_automation_simple_demo/
```

5.1 Adjust inventory to your needs
```bash
 demo_inventory.yml
```

5.2. Start playbook with: 
```bash
 ansible-playbook -i demo_inventory.yml mgmt_automation_simple_demo.yml -v
```

!!! Note: 
Make sure:
- Management server is reachable via 443
- API is running and allowed for automation server IP