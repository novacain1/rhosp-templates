#!/bin/bash
#<2019-04-09 dcain>
# -------------------------------------------------------
# This script only needs to be run once after initial deployment
# Assumes systems with subscriptions
# Written specifically for RDU2 Lab

# -------------------------------------------------------
# HARD CODED VARIABLES
inventory_file=$HOME/ansible/hosts
stack_name=rdu

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
source ~/rdurc

#upload fedora 30 and other cloud images
echo "Uploading fedora 30 and rhel7 cloud images to image store"
cd $HOME/postdeploy-scripts/
#curl -L https://download.fedoraproject.org/pub/fedora/linux/releases/30/Cloud/x86_64/images/Fedora-Cloud-Base-30-1.2.x86_64.qcow2 > fedora30.qcow2
qemu-img convert fedora30.qcow2 fedora30.raw
qemu-img convert rhel7.qcow2 rhel7.raw
openstack image create --disk-format raw --container-format bare --file $HOME/postdeploy-scripts/fedora30.raw  --public fedora30
openstack image create --disk-format raw --container-format bare --file $HOME/postdeploy-scripts/rhel7.raw  --public rhel7
openstack image create --disk-format raw --container-format bare --file $HOME/postdeploy-scripts/pxeboot.img  --public pxeboot
#openstack image create --disk-format qcow2 --container-format bare --file $HOME/postdeploy-scripts/rhel-guest-image-7.4-263.x86_64.qcow2 --public rhel7

#create new project/user/tenant
openstack user create redhat --password redhat --email redhat@example.com
openstack project create redhat-tenant
openstack role add --project redhat-tenant --user redhat _member_
openstack quota set --secgroups 30 --secgroup-rules 200 --ports 200 redhat-tenant
openstack quota set --instances 30 redhat-tenant
openstack quota set --cores 150 redhat-tenant
openstack quota set --ram 294912 redhat-tenant
openstack quota set --volumes 30 redhat-tenant
openstack quota set --gigabytes 4800 redhat-tenant
tenantUser=$(openstack user list | awk '/redhat/ {print $2}')
tenant=$(openstack project list | awk '/redhat/ {print $2}')

#create custom flavors and flavors for openshift 3
openstack flavor create --public m1.tiny --id auto --ram 512 --disk 5 --vcpus 1 --public
openstack flavor create --public m1.small --id auto --ram 1024 --disk 10 --vcpus 1 --public
openstack flavor create --public m1.medium --id auto --ram 4096 --disk 20 --vcpus 1 --public
openstack flavor create --public m1.ocpmaster --id auto --ram 16384 --disk 45 --vcpus 4 --public
openstack flavor create --public m1.ocpnode --id auto --ram 8192 --disk 20 --vcpus 1 --public

#openshift 4 flavor
openstack flavor create --public m1.ocp4master --id auto --ram 16384 --disk 120 --vcpus 4 --public
openstack flavor create --public m1.ocp4ocs --id auto --ram 65536 --disk 120 --vcpus 16 --public

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
openstack subnet create tenant1-subnet --network tenant1 --dhcp --allocation-pool start=172.255.1.2,end=172.255.1.254 --dns-nameserver 10.11.175.8 --gateway 172.255.1.1 --subnet-range 172.255.1.0/24
openstack router create tenant1-router
subnet_id=$(neutron subnet-list | awk ' /172.255.1./ {print $2 } ')
openstack router add subnet tenant1-router $subnet_id

#provider networks as admin user for non-DPDK setup
#vlans 100-101
source ~/rdurc
openstack network create provider100 --provider-physical-network datacentre --provider-network-type vlan --provider-segment 100 --share
openstack subnet create provider100-subnet --network provider100 --dhcp --allocation-pool start=192.168.100.5,end=192.168.100.199 --dns-nameserver 10.11.175.8 --gateway 192.168.100.1 --subnet-range 192.168.100.0/24
openstack network create provider101 --provider-physical-network datacentre --provider-network-type vlan --provider-segment 101 --share
openstack subnet create provider101-subnet --network provider101 --dhcp --allocation-pool start=192.168.101.5,end=192.168.101.254 --dns-nameserver 10.11.175.8 --gateway 192.168.101.1 --subnet-range 192.168.101.0/24

# Floating IP network as admin user
openstack network create floating --external --provider-network-type flat --provider-physical-network datacentre
openstack subnet create floating-subnet --network floating --no-dhcp --gateway 10.11.175.254 --allocation-pool start=10.11.175.100,end=10.11.175.150 --dns-nameserver 10.11.175.8 --subnet-range 10.11.175.0/24
route_id=$(openstack router list | awk ' /tenant1/ { print $2 } ')
ext_net_id=$(openstack network list | awk ' /floating/ { print $2 } ')
#openstack router set $route_id --external-gateway $ext_net_id
neutron router-gateway-set $route_id $ext_net_id

# Baremetal network for BM nodes
openstack network create baremetal --provider-physical-network datacentre --provider-network-type vlan --provider-segment 68 --share
# disabling to pxe boot in instances on this network
openstack network set --disable-port-security baremetal
#openstack subnet create baremetal-subnet --network baremetal --dhcp --allocation-pool start=192.168.68.50,end=192.168.68.79 --dns-nameserver 10.11.175.8 --gateway 192.168.68.1 --subnet-range 192.168.68.0/25
openstack subnet create baremetal-subnet --network baremetal --no-dhcp --dns-nameserver 10.11.175.8 --gateway 192.168.68.1 --subnet-range 192.168.68.0/25

# Floating IP allocate 2
source ~/redhatrc
for i in {1..2}
do
    openstack floating ip create floating
done

# OCP4 Ports
source ~/rdurc
openstack port create --network baremetal --project redhat-tenant --fixed-ip subnet=baremetal-subnet,ip-address=192.168.68.4 --mac-address fa:16:3e:48:20:25 rdu-bootstrap42
openstack port create --network baremetal --project redhat-tenant --fixed-ip subnet=baremetal-subnet,ip-address=192.168.68.5 --mac-address fa:16:3e:72:c1:cd rdu-master42-0
openstack port create --network baremetal --project redhat-tenant --fixed-ip subnet=baremetal-subnet,ip-address=192.168.68.6 --mac-address fa:16:3e:2d:2a:2a rdu-master42-1
openstack port create --network baremetal --project redhat-tenant --fixed-ip subnet=baremetal-subnet,ip-address=192.168.68.7 --mac-address fa:16:3e:13:1a:4c rdu-master42-2
openstack port create --network baremetal --project redhat-tenant --fixed-ip subnet=baremetal-subnet,ip-address=192.168.68.15 --mac-address fa:16:3e:13:1a:5a rdu-ocs42-0
openstack port create --network baremetal --project redhat-tenant --fixed-ip subnet=baremetal-subnet,ip-address=192.168.68.16 --mac-address fa:16:3e:13:1a:5b rdu-ocs42-1
openstack port create --network baremetal --project redhat-tenant --fixed-ip subnet=baremetal-subnet,ip-address=192.168.68.17 --mac-address fa:16:3e:13:1a:5c rdu-ocs42-2

#openstack server create --image pxeboot --flavor m1.ocp4master --key-name dcain --port rdu-bootstrap42 rdu-bootstrap42
#openstack server create --image pxeboot --flavor m1.ocp4master --key-name dcain --port rdu-master42-0 rdu-master42-0
#openstack server create --image pxeboot --flavor m1.ocp4master --key-name dcain --port rdu-master42-1 rdu-master42-1
#openstack server create --image pxeboot --flavor m1.ocp4master --key-name dcain --port rdu-master42-2 rdu-master42-2
#openstack server create --image pxeboot --flavor m1.ocp4ocs --key-name dcain --port rdu-ocs42-0 rdu-ocs42-0
#openstack server create --image pxeboot --flavor m1.ocp4ocs --key-name dcain --port rdu-ocs42-1 rdu-ocs42-1
#openstack server create --image pxeboot --flavor m1.ocp4ocs --key-name dcain --port rdu-ocs42-2 rdu-ocs42-2
}

function ocbare {
# ironic baremetal configuration

echo "Creating Overcloud postdeployment baremetal configuration"
source ~/rdurc
openstack baremetal create ~/templates/baremetal.yaml
openstack baremetal node list

# upload ramdisk and kernel images to image store
# 21-Dec removed public from image to avoid seeing in glance
openstack image create --container-format aki --disk-format aki --file ~/images/ironic-python-agent.kernel deploy-kernel
openstack image create --container-format ari --disk-format ari --file ~/images/ironic-python-agent.initramfs deploy-ramdisk

# set baremetal servers to use deploy kernel/ramdisk
DEPLOY_KERNEL=$(openstack image show deploy-kernel -f value -c id)
DEPLOY_RAMDISK=$(openstack image show deploy-ramdisk -f value -c id)
openstack baremetal node set baremetal1 --driver-info deploy_kernel=$DEPLOY_KERNEL --driver-info deploy_ramdisk=$DEPLOY_RAMDISK
openstack baremetal node set baremetal2 --driver-info deploy_kernel=$DEPLOY_KERNEL --driver-info deploy_ramdisk=$DEPLOY_RAMDISK
openstack baremetal node set baremetal3 --driver-info deploy_kernel=$DEPLOY_KERNEL --driver-info deploy_ramdisk=$DEPLOY_RAMDISK
openstack baremetal node set baremetal4 --driver-info deploy_kernel=$DEPLOY_KERNEL --driver-info deploy_ramdisk=$DEPLOY_RAMDISK

# start cleaning, wipe disk
openstack baremetal node manage baremetal1
openstack baremetal node provide baremetal1

echo "Uploading RHEL7 images to Image Storage for overcloud"
KERNEL_ID=$(openstack image create --file ~/images/overcloud-full.vmlinuz --public --container-format aki --disk-format aki -f value -c id overcloud-full.vmlinuz)
RAMDISK_ID=$(openstack image create --file ~/images/overcloud-full.initrd --public --container-format ari --disk-format ari -f value -c id overcloud-full.initrd)
openstack image create --file ~/images/overcloud-full.qcow2 --public --container-format bare --disk-format qcow2 --property kernel_id=$KERNEL_ID --property ramdisk_id=$RAMDISK_ID rhel7-baremetal

openstack flavor create --ram 1024 --disk 40 --vcpus 1 baremetal
openstack flavor set baremetal --property resources:CUSTOM_BAREMETAL=1
openstack flavor set baremetal --property resources:VCPU=0
openstack flavor set baremetal --property resources:MEMORY_MB=0
openstack flavor set baremetal --property resources:DISK_GB=0

echo "Creating aggregate that covers OpenStack Controller systems"
openstack aggregate create --property baremetal=true baremetal-hosts
openstack host list
openstack aggregate add host baremetal-hosts rdu-controller01.raleigh.redhat.com
openstack aggregate add host baremetal-hosts rdu-controller02.raleigh.redhat.com
openstack aggregate add host baremetal-hosts rdu-controller03.raleigh.redhat.com

echo "Utilizing keypair created earlier for convenience"
openstack keypair create --private-key ~/dcain.pem ironicOC

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

if [ $1 = "ocbare" ]; then
    ocbare
fi

exit 0
