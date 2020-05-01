# Gateways reachability tests vis icmp, ssh, https

# 1. Purpose

The role allows to performs gateways reachability tests via icmp, ssh, https. 

## 2. Input data
A gateways list in csv format is used as input.
Example list is located in:
```bash
vars/gatewaysList_example.csv
```
The gateways list can be generated by means of inventory role (will be) located in roles/mgmt/. 


## 3. Output data 
The reachability tests results are stored in folder output/ in following format:

```bash
cma;gw_name;gw_ip;icmp;ssh;https
```

## 4. How role works

- The gateways csv is converted to json
- Reachabiliy test is performed to all gateways listed in json file. 



## 5. How to start the role

The role can be started in the way presented in the playbook below. 
This playbook is located in folder playbooks/

Change the vars: section according to your needs if required. 

```bash
---
  - hosts: localhost
    connection: local
    gather_facts: no

    vars:    
      outputFolder: ../output
      outputFile: reachabilityCheck_
      inventoryCSVfile: ../vars/gatewaysList_20200331.csv
      inventoryJsonfile: ../vars/gatewaysList_20200331.json

    roles:      
      - roles/gateways/gws_reachability_check/
```

Command to run the role:
```bash
ansible-playbook  playbooks/gws_reachability_check.yml -v
```