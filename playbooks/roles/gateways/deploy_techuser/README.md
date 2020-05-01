# Deployment of techuser "robot" on gatewys

To start to administrate the gateways, following needs to be done on all gateways:
- Techuser "robot" installation
- The public key of "robot" copy


It can be performed with this role in steps described below. 

### 1. Prepare your account
Make sure the user account (you use to install techuser) has /bin/bash shell on all gateways. 
```bash
set user <user_user_id> shell /bin/bash
```

### 2. Checkout the whole project in your account


### 3. Prepare ansible inventory 

3.1 Prepare gateways list

Put the list of gateways in inventory
ans_inventory/inventory_gws.yml

Use following format:

```bash
[GWs]
10.213.226.2 name="dcsyd-fw-sma-1"
10.213.226.3 name="dcsyd-fw-sma-2"
10.16.251.211 name="fra-cloud-vpn-r-1"
```

3.2 Put your username

```bash
[GWs:vars]
ansible_user=<my_username>
```


### 4. Copy techuser "robot" public key
Copy techuser "robot" public key to your local folder and configure the path in the inventory. 

```bash
[GWs:vars]
local_key_path=/home/<user_user_id>/.ssh/
local_key_name=id_rsa_robot.pub
```

### 5. Configure ssh-agent
If your private key is password protected, configure ssh agent:

```bash
eval `ssh-agent`
ssh-add /home/<user_user_id>/.ssh/id_rsa
```

### 6. Run playbooks

```bash
ansible-playbook -i ans_inventory/inventory_gws.yml playbooks/deploy_techuser.yml
```