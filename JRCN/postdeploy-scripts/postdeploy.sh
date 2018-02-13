#!/bin/bash
#<2018-01-10 dcain>
# -------------------------------------------------------
# This script only needs to be run once after initial deployment
# Assumes systems with subscriptions
# Written specifically for VCOv2 Demo

# -------------------------------------------------------
# HARD CODED VARIABLES
inventory_file=$HOME/ansible/hosts
stack_name=vco2

# -------------------------------------------------------
# SAFETY CHECKS
if [ "$#" -lt 1 ]; then
  echo "Pass: $0 lldp --> turn on lldp via script and package installs"
  echo "Pass: $0 ssh --> allow ssh as root via external interface on all nodes"
  echo "Pass: $0 ocpost --> enabling fencing, post deployment verification"
  exit 1
fi

test "$(whoami)" != 'stack' && (echo "This must be run by the stack user on the
undercloud"; exit 1)

controllers=$(grep controllers $inventory_file -A 1 | tail -1 | awk {'print $1'})
if [[ -z $controllers ]]; then
    echo "No host under [controllers] in $inventory_file. Exiting. "
exit 1 
fi

if ! hash ansible 2>/dev/null; then
    echo "Cannot find ansible command. Exiting. "
exit 1 
fi

function lldp {
# -------------------------------------------------------
# INSTALL PRE-REQ SOFTWARE & COPY LLDP SCRIPT TO ALL NODES
echo "Installing software via yum and copying lldp script to enable network discovery"
ansible -m shell -a "yum -y install lldpad" -i $inventory_file all -b
ansible -m copy -a "src=$HOME/postdeploy-scripts/lldp.sh dest=/home/heat-admin/lldp.sh mode=0744" -i $inventory_file all -b
ansible -m shell -a "systemctl start lldpad" -i $inventory_file all -b
ansible -m shell -a "systemctl enable lldpad" -i $inventory_file all -b
ansible -m shell -a "cd /home/heat-admin; ./lldp.sh" -i $inventory_file all -b

}

function ssh {
# -------------------------------------------------------
# ALLOW SSH AS ROOT VIA PASSWORD AUTHENTICATION
echo "Allowing ssh as root, password authentication"
ansible -m shell -a "sed -i 's|[#]*PasswordAuthentication no|PasswordAuthentication yes|g' /etc/ssh/sshd_config" -i $inventory_file all -b --ssh-common-args='-o StrictHostKeyChecking=no'
ansible -m shell -a "systemctl restart sshd.service" -i $inventory_file all -b
}

function ocpost {

echo "Creating Overcloud postdeployment validation/verification"
source ~/vco2rc

#upload fedora 27 cloud image
echo "Uploading fedora 27 and rhel7 cloud images to image store"
cd $HOME/postdeploy-scripts/
curl -L https://download.fedoraproject.org/pub/fedora/linux/releases/27/CloudImages/x86_64/images/Fedora-Cloud-Base-27-1.6.x86_64.qcow2 > fedora27.qcow2
openstack image create --disk-format qcow2 --container-format bare --file $HOME/postdeploy-scripts/fedora27.qcow2  --public fedora27
#openstack image create --disk-format qcow2 --container-format bare --file $HOME/postdeploy-scripts/rhel-guest-image-7.4-263.x86_64.qcow2 --public rhel7

#create new project/user/tenant
openstack user create redhat --password redhat --email redhat@example.com
openstack project create redhat-tenant
openstack role add --project redhat-tenant --user redhat _member_
tenantUser=$(openstack user list | awk '/redhat/ {print $2}')
tenant=$(openstack project list | awk '/redhat/ {print $2}')

#quota updates
nova quota-update $tenant --instances 500 --cores 500 --ram 1228800
cinder quota-update --volumes 500 --gigabytes 216000 $tenant
neutron quota-update --tenant_id $tenant --port 100000 --floatingip 200

#create custom flavors
openstack flavor create --public m1.tiny --id auto --ram 512 --disk 1 --public
openstack flavor create --public m1.medium --id auto --ram 4096 --disk 10 --public
#openstack flavor create --id auto --ram 1024 --disk 10 --vcpus 2 dpdk-flavor.s1 --public
#openstack flavor set \
#  --property hw:mem_page_size=large \
#  --property hw:cpu_policy=dedicated \
#  --property hw:cpu_thread_policy=prefer \
#  --property hw:numa_mempolicy=preferred \
#  --property hw:numa_nodes=1 \
#  dpdk-flavor.s1

#aggregates and hosts
#openstack aggregate create --zone=dpdk1 dpdk1
#openstack aggregate create --zone=dpdk2 dpdk2
#openstack aggregate add host dpdk1 $stack_name-compute-0.localdomain
#openstack aggregate add host dpdk2 $stack_name-compute-1.localdomain

#security groups inbound exception as admin user
admin_project_id=$(openstack project list | grep admin | awk '{print $2}')
admin_sec_group_id=$(openstack security group list | grep $admin_project_id | awk '{print $2}')

openstack security group rule create $admin_sec_group_id --protocol icmp --ingress
openstack security group rule create $admin_sec_group_id --protocol icmp --egress
openstack security group rule create $admin_sec_group_id --protocol tcp --dst-port 22 --ingress
openstack security group rule create $admin_sec_group_id --protocol tcp --dst-port 22 --egress

#security groups exception as redhat user
source ~/redhatovercloudrc
neutron security-group-rule-create --direction ingress --protocol icmp default
neutron security-group-rule-create --direction ingress --protocol tcp --port_range_min 22 --port_range_max 22 default

# Keypair creation as redhat user for SSH through floating ip
openstack keypair create dcain > ~/dcain.pem
chmod 600 ~/dcain.pem

# Tenant Networks as admin user
#source ~/vco2rc
#openstack network create provider25 --provider-physical-network datacentre --provider-network-type vlan --provider-segment 26 --share
#openstack subnet create provider25-subnet --network provider25 --dhcp --dns-nameserver 192.168.0.254 --subnet-range 172.21.26.0/24
#source ~/redhatovercloudrc
#openstack router create provider25-router
#source ~/vco2rc
#subnet_id=$(neutron subnet-list | awk ' /172.16.200./ {print $2 } ')
#openstack router add subnet mgmt200-router $subnet_id

#provider DPDK networks as admin user
#source ~/rhlen-mwcrc
#openstack network create dpdk211 --provider-physical-network dpdk --provider-network-type vlan --provider-segment 211 --share
#openstack subnet create dpdk211-subnet --network dpdk211 --dhcp --allocation-pool start=172.16.211.2,end=172.16.211.100 --dns-nameserver 172.21.172.1 --gateway 172.16.211.1 --subnet-range 172.16.211.0/24
#openstack network create dpdk212 --provider-physical-network dpdk --provider-network-type vlan --provider-segment 212 --share
#openstack subnet create dpdk212-subnet --network dpdk212 --dhcp --allocation-pool start=172.16.212.2,end=172.16.212.100 --dns-nameserver 172.21.172.1 --gateway 172.16.212.1 --subnet-range 172.16.212.0/24

#provider network as admin user for non-DPDK setup
source ~/vco2rc
openstack network create provider26 --provider-physical-network datacentre --provider-network-type vlan --provider-segment 26 --share
openstack subnet create provider26-subnet --network provider26 --dhcp --allocation-pool start=172.21.26.3,end=172.21.26.254 --dns-nameserver 192.168.0.254 --gateway 172.21.26.1 --subnet-range 172.21.26.0/24

# Floating IP network as admin user
openstack network create floating --external --provider-network-type vlan --provider-physical-network datacentre --provider-segment 25
openstack subnet create floating-subnet --network floating --no-dhcp --gateway 172.21.25.1 --allocation-pool start=172.21.25.171,end=172.21.25.254 --dns-nameserver 192.168.0.254 --subnet-range 172.21.25.0/24

# Floating IP allocate and router setup
#route_id=$(openstack router list | awk ' /mgmt200/ { print $2 } ')
#ext_net_id=$(openstack network list | awk ' /floating/ { print $2 } ')
#neutron router-gateway-set $route_id $ext_net_id

# Floating IP allocate 15
source ~/redhatovercloudrc
for i in {1..3}
do
    openstack floating ip create floating
done

# instance booting
#openstack server create --flavor dpdk-flavor.s1 --availability-zone dpdk1 --image rhel7 --nic net-id=38e99f1a-6168-4006-bfcf-15d7f1a50608 --nic net-id=50e66689-b208-4ca1-a681-55dc9db764f0 --key-name dcain vnf-0-1
#openstack server create --flavor dpdk-flavor.s1 --availability-zone dpdk2 --image rhel7 --nic net-id=38e99f1a-6168-4006-bfcf-15d7f1a50608 --nic net-id=50e66689-b208-4ca1-a681-55dc9db764f0 --key-name dcain vnf-1-1
}

if [ $1 = "lldp" ]; then
    lldp
fi

if [ $1 = "ssh" ]; then
    ssh
fi

if [ $1 = "ocpost" ]; then
    ocpost
fi

exit 0
