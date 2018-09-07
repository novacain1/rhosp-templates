#!/bin/bash
#<2018-09-04 dcain>
# -------------------------------------------------------
# This script only needs to be run once after initial deployment
# Assumes systems with subscriptions
# Written specifically for RHT

# -------------------------------------------------------
# HARD CODED VARIABLES
inventory_file=$HOME/ansible/hosts
stack_name=rht

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
source ~/rhtrc

#upload fedora 28 cloud image
echo "Uploading fedora 28 and rhel7 cloud images to image store"
cd $HOME/postdeploy-scripts/
curl -L https://download.fedoraproject.org/pub/fedora/linux/releases/28/Cloud/x86_64/images/Fedora-Cloud-Base-28-1.1.x86_64.qcow2 > fedora28.qcow2
qemu-img convert fedora28.qcow2 fedora28.raw
openstack image create --disk-format raw --container-format bare --file $HOME/postdeploy-scripts/fedora28.raw  --public fedora28
#openstack image create --disk-format raw --container-format bare --file $HOME/postdeploy-scripts/rhel7.raw  --public rhel7
#openstack image create --disk-format qcow2 --container-format bare --file $HOME/postdeploy-scripts/rhel-guest-image-7.4-263.x86_64.qcow2 --public rhel7

#create new project/user/tenant
openstack user create redhat --password redhat --email redhat@example.com
openstack project create redhat-tenant
openstack role add --project redhat-tenant --user redhat _member_
tenantUser=$(openstack user list | awk '/redhat/ {print $2}')
tenant=$(openstack project list | awk '/redhat/ {print $2}')

#quota updates
#nova quota-update $tenant --instances 500 --cores 500 --ram 1228800
#cinder quota-update --volumes 500 --gigabytes 216000 $tenant
#neutron quota-update --tenant_id $tenant --port 100000 --floatingip 200

#create custom flavors
openstack flavor create --public m1.tiny --id auto --ram 512 --disk 5 --public
openstack flavor create --public m1.small --id auto --ram 1024 --disk 10 --public

#security groups inbound exception as admin user
admin_project_id=$(openstack project list | grep admin | awk '{print $2}')
admin_sec_group_id=$(openstack security group list | grep $admin_project_id | awk '{print $2}')

openstack security group rule create $admin_sec_group_id --protocol icmp --ingress
openstack security group rule create $admin_sec_group_id --protocol icmp --egress
openstack security group rule create $admin_sec_group_id --protocol tcp --dst-port 22 --ingress
openstack security group rule create $admin_sec_group_id --protocol tcp --dst-port 22 --egress

#security groups exception as redhat user
source ~/redhatrc
neutron security-group-rule-create --direction ingress --protocol icmp default
neutron security-group-rule-create --direction ingress --protocol tcp --port_range_min 22 --port_range_max 22 default

# Keypair creation as redhat user for SSH through floating ip
openstack keypair create dcain > ~/dcain.pem
chmod 600 ~/dcain.pem

# Tenant Network as redhat user
openstack network create tenant1
openstack subnet create tenant1-subnet --network tenant1 --dhcp --allocation-pool start=172.255.1.2,end=172.255.1.254 --dns-nameserver 10.12.49.8 --gateway 172.255.1.1 --subnet-range 172.255.1.0/24
openstack router create tenant1-router
subnet_id=$(neutron subnet-list | awk ' /172.255.1./ {print $2 } ')
openstack router add subnet tenant1-router $subnet_id

#provider networks as admin user for non-DPDK setup
#vlans 100
source ~/rhtrc
openstack network create provider100 --provider-physical-network provider --provider-network-type vlan --provider-segment 100 --share
openstack subnet create provider100-subnet --network provider100 --dhcp --allocation-pool start=192.168.100.5,end=192.168.100.254 --dns-nameserver 10.12.49.8 --gateway 192.168.100.1 --subnet-range 192.168.100.0/23

# Floating IP network as admin user
openstack network create floating --external --provider-network-type flat --provider-physical-network datacentre
openstack subnet create floating-subnet --network floating --no-dhcp --gateway 10.12.49.254 --allocation-pool start=10.12.49.100,end=10.12.49.150 --dns-nameserver 10.12.49.8 --subnet-range 10.12.49.0/24
route_id=$(openstack router list | awk ' /tenant1/ { print $2 } ')
ext_net_id=$(openstack network list | awk ' /floating/ { print $2 } ')
#openstack router set $route_id --external-gateway $ext_net_id
neutron router-gateway-set $route_id $ext_net_id

# Floating IP allocate 15
source ~/redhatovercloudrc
for i in {1..3}
do
    openstack floating ip create floating
done
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
