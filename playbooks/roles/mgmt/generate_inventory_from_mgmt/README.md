# Gateways inventory generator from MGMT (Check Point management server)

# 1. Purpose

Generates gateways inventory from MGMT database via cpmiquerybin.


## 2. Input data
Inventory file in 
```bash
ans_inventory/inventory_create_gws_inventory.yml
```


## 3. Output data 
Csv report stored into folder provided in: 
```bash
ans_inventory/inventory_create_gws_inventory.yml
```

## 4. How role works
The role works in following steps

1.  Ansible accesses the MGMT via ssh
2.  Ansible sends a shell script to MGMT
3.  Scripts collects the gateways inventory via cpmiquerybin



## 5. How to start the role

5.1 Adjust ansible inventory accoding to your needs:
```bash
ans_inventory/inventory_create_gws_inventory.yml
```

5.2 Start the role in following way with following playbook:

Command to run the role:
```bash
ansible-playbook -i ans_inventory/inventory_create_gws_inventory.yml playbooks/generate_inventory_from_MGMT.yml -v
```

You can follow the progreess of inventory creation by looking at logs created by shell script on MGMT in folder provided in inventory behind the variable: "invScriptLogsFolderRemote".

Find playbooks in folder playbooks/

Playbook:
```bash
---
  - hosts: "MGMT"
    gather_facts: no
      
    roles:      
      # In this role, the gateway are accessed from Ansible via ssh
      - roles/mgmt/generate_inventory_from_mgmt
```