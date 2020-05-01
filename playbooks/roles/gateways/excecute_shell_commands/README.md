# Execution of shell and clish commands on gateways

## 1. Purpose

The role allows to execute shell and clish commands on the gateways and to collects commands output.
The role can be used for:

- Data collection on gateways
- Gateways conifiguration 

!!! Note: Be careful when configuring new commands to be executed on the gateways. 
It is highly recommended to test each command on a single gataway before executing them on a range of gateways.


## 2. Input data

2.1 List of shell or clish commands
```bash
vars/shellCommandsList.yml
```

Following yml format is to be used:
```bash
---
shellCommands:
- {'name': '<Command name>', 'command': '<shell command>'}
```

Example:
```bash
---
shellCommands:
- {'name': 'CPU utilization: mpstat', 'command': '. /opt/CPshared/5.0/tmp/.CPprofile.sh; mpstat'}
- {'name': 'Memory utilization: free -m', 'command': 'free -m'}
- {'name': 'Intefaces stats, netstat -i', 'command': 'netstat -i'}
```

2.2 Ansible inventory inventory_gws.yml
Use following format for the hosts:

```bash
[GWs]
10.213.226.2 name="dcsyd-fw-sma-1"
10.213.226.3 name="dcsyd-fw-sma-2"
10.16.251.211 name="fra-cloud-vpn-r-1"
```

Note!!! Name parameter is required for the role.


## 3. Output data 
Command outputs are collected in folder output/. 


## 4. How role works

- The role iterates via commands from vars/shellCommandsList.yml
- Executes commands on the gateways 
- Stores commands outputs into output/. One file per gateways is created. 


## 5. How to start the role

The role can be started in the way presented in the playbook below. 
This playbook is located in folder playbooks/

Playbook:
```bash
---
  - hosts: "GWs"
    gather_facts: no
   
    roles:
      - roles/gateways/excecute_shell_commands    
```

Command to run the role:
```bash
ansible-playbook -i ans_inventory/inventory_gws.yml playbooks/execute_shell_commands.yml
```
