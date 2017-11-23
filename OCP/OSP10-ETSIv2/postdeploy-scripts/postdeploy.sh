#!/bin/bash
#<2017-11-22 dcain>
# -------------------------------------------------------
# This script only needs to be run once after initial deployment
# Assumes systems with subscriptions
# Written specifically for ETSI Plugfest #2

# -------------------------------------------------------
# HARD CODED VARIABLES
inventory_file=$HOME/ansible/hosts

# -------------------------------------------------------
# SAFETY CHECKS
if [ "$#" -lt 1 ]; then
  echo "Pass: $0 drivers --> mlnx drivers on all the hosts"
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

function drivers {
# -------------------------------------------------------
# INSTALL PRE-REQ SOFTWARE & COPY MLNX FIRMWARE TO OCP NODES
echo "Installing software via yum and copying Mellanox firmware"
ansible -m shell -a "yum -y install tcl gcc-gfortran tcsh tk" -i $inventory_file 'all:!storages' -b
ansible -m copy -a "src=/home/stack/ansible/MLNX_OFED_LINUX-4.0-2.0.0.1-rhel7.3-x86_64.tgz dest=/home/heat-admin/MLNX_OFED_LINUX-4.0-2.0.0.1-rhel7.3-x86_64.tgz mode=0744" -i $inventory_file 'all:!storages' -b
ansible -m shell -a "cd /home/heat-admin; tar xvzf MLNX_OFED_LINUX-4.0-2.0.0.1-rhel7.3-x86_64.tgz" -i $inventory_file 'all:!storages' -b
ansible -m shell -a "cd /home/heat-admin/MLNX_OFED_LINUX-4.0-2.0.0.1-rhel7.3-x86_64; ./mlnxofedinstall --without-fw-update --force" -i $inventory_file 'all:!storages' -b
ansible -m shell -a "mlnx_tune" -i $inventory_file 'all:!storages' -b

}

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
echo "Enabling fencing on the controller nodes..."
$HOME/postdeploy-scripts/configure_fence.sh enable

echo "Creating Overcloud postdeployment validation/verification"
source ~/rhlen-etsirc

#upload fedora 27 cloud image
echo "Uploading fedora 27 cloud image to image store"
cd $HOME/postdeploy-scripts/
#curl -L https://download.fedoraproject.org/pub/fedora/linux/releases/27/CloudImages/x86_64/images/Fedora-Cloud-Base-27-1.6.x86_64.qcow2 > fedora27.qcow2
#qemu-img convert $HOME/postdeploy-scripts/fedora27.qcow2 fedora27.raw
#openstack image create --disk-format raw --container-format bare --file $HOME/postdeploy-scripts/fedora27.raw  --public fedora27

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
openstack flavor create --public m1.medium --id auto --ram 4096 --disk 10 --public

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
nova keypair-add dcain > ~/dcain.pem
chmod 600 ~/dcain.pem

# Tenant Network as redhat user
#openstack network create tenant1 --provider-network-type=vxlan --provider-segment 100
#openstack subnet create --network tenant1 --subnet-range 10.10.0.0/18 tenant1-subnet
neutron net-create tenant1
neutron subnet-create --name tenant_subnet --gateway 10.10.0.1 tenant1 10.10.0.0/18 --dns-nameserver 8.8.8.8 --allocation-pool start=10.10.0.5,end=10.10.63.254
neutron router-create tenant1-router
subnet_id=$(neutron subnet-list | awk ' /10.10./ {print $2 } ')
neutron router-interface-add tenant1-router $subnet_id

#provider network as admin user
source ~/rhlen-etsirc
openstack network create provider --provider-physical-network datacentre --provider-network-type vlan --provider-segment 26 --share
openstack subnet create provider-subnet --network provider --dhcp --allocation-pool start=172.22.26.2,end=172.22.26.254 --dns-nameserver 8.8.8.8 --gateway 172.22.26.1 --subnet-range 172.22.26.0/24

# Floating IP network as admin user
openstack network create floating --external --provider-network-type vlan --provider-physical-network datacentre --provider-segment 24
openstack subnet create floating-subnet --network floating --no-dhcp --gateway 172.22.24.129 --allocation-pool start=172.22.24.171,end=172.22.24.254 --dns-nameserver 8.8.8.8 --subnet-range 172.22.24.128/25
route_id=$(neutron router-list | awk ' /tenant1/ { print $2 } ')
ext_net_id=$(neutron net-list | awk ' /floating/ { print $2 } ')
neutron router-gateway-set $route_id $ext_net_id

# Floating IP allocate 15
source ~/redhatovercloudrc
for i in {1..3}
do
    nova floating-ip-create floating
done
}

if [ $1 = "drivers" ]; then
    drivers
fi

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
