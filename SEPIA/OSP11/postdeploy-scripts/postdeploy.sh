#!/bin/bash
#<2017-06-26 dcain>
# -------------------------------------------------------
# This script only needs to be run once after initial deployment
# Assumes systems with subscriptions
# Written specifically for OPNFV Summit Bejing CN

# -------------------------------------------------------
# HARD CODED VARIABLES
inventory_file=$HOME/postdeploy-scripts/hosts

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

#controllers=$(grep controllers $inventory_file -A 1 | tail -1 | awk {'print $1'})
#if [[ -z $controllers ]]; then
#    echo "No host under [controllers] in $inventory_file. Exiting. "
#exit 1 
#fi

if ! hash ansible 2>/dev/null; then
    echo "Cannot find ansible command. Exiting. "
exit 1 
fi


function lldp {
# -------------------------------------------------------
# INSTALL PRE-REQ SOFTWARE & COPY LLDP SCRIPT TO ALL NODES
echo "Installing software via yum and copying lldp script to enable network discovery"
ansible -m copy -a "src=overcloud.repo dest=/etc/yum.repos.d/overcloud.repo mode=0744" -i $inventory_file all -b --ssh-common-args='-o StrictHostKeyChecking=no'
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
echo "Enabling fencing on the controller nodes..."
$HOME/postdeploy-scripts/configure_fence.sh enable

echo "Creating Overcloud postdeployment validation/verification"
source ~/sepiarc

#upload fedora 25 cloud image
echo "Uploading fedora 25 cloud image to image store"
cd $HOME/postdeploy-scripts/
curl -L https://download.fedoraproject.org/pub/fedora/linux/releases/25/CloudImages/x86_64/images/Fedora-Cloud-Base-25-1.3.x86_64.qcow2 > fedora25.qcow2
qemu-img convert $HOME/postdeploy-scripts/fedora25.qcow2 fedora25.raw
openstack image create --disk-format raw --container-format bare --file $HOME/postdeploy-scripts/fedora25.raw  --public fedora25

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

#create custom flavor
openstack flavor create --public m1.tiny --id auto --ram 512 --disk 1 --public

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
nova keypair-add dcain > ~/dcain.pem
chmod 600 ~/dcain.pem

# Tenant Network as redhat user
#openstack network create tenant1 --provider-network-type=vxlan --provider-segment 100
#openstack subnet create --network tenant1 --subnet-range 10.10.0.0/18 tenant1-subnet
openstack network create tenant1
openstack subnet create tenant_subnet --network tenant1 --no-dhcp --gateway 10.10.0.1 --allocation-pool start=10.10.0.5,end=10.10.63.254 --dns-nameserver 8.8.8.8 --subnet-range 10.10.0.0/18
openstack router create tenant1-router
subnet_id=$(openstack subnet-list | awk ' /10.10./ {print $2 } ')
openstack router add subnet tenant1-router $subnet_id

#provider network as admin user
#source ~/sepiarc
#openstack network create provider --provider-physical-network datacentre --provider-network-type vlan --provider-segment 157 --share
#openstack subnet create provider-subnet --network provider --dhcp --allocation-pool start=172.21.157.10,end=172.21.157.100 --dns-nameserver 8.8.8.8 --gateway 172.21.157.1 --subnet-range 172.21.157.0/24

# Floating IP network as admin user
source ~/sepiarc
openstack network create floating --external --provider-network-type flat --provider-physical-network floating
openstack subnet create floating-subnet --network floating --no-dhcp --gateway 172.21.15.254 --allocation-pool start=172.21.1.160,end=172.21.1.254 --dns-nameserver 8.8.8.8 --subnet-range 172.21.0.0/20
route_id=$(openstack router list | awk ' /tenant1/ { print $2 } ')
ext_net_id=$(openstack network list | awk ' /floating/ { print $2 } ')
openstack router set $route_id --external-gateway $ext_net_id

# Floating IP allocate 15
source ~/redhatrc
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
