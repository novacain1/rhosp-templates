#!/bin/bash
#<2016-11-25 dcain>
# -------------------------------------------------------
# This script only needs to be run once during initial deployment
# Be sure to deploy Ceph first before running this
# Restarts glance, cinder, nova so they repoll the new ceph cluster
# Borrowed parts from John Fulton at Red Hat

# -------------------------------------------------------
# HARD CODED VARIABLES
inventory_file=/home/stack/postdeploy-automation/hosts
instances_inventory_file=/home/stack/postdeploy-automation/instances-hosts

# -------------------------------------------------------
# SAFETY CHECKS
if [ "$#" -lt 1 ]; then
  echo "Pass: $0 preceph --> gets repo files over to nodes for ceph-ansible"
  echo "Pass: $0 converged --> ceph ansible already run, converged operation"
  echo "Pass: $0 standalone --> ceph ansible already run, standalone operation"
  echo "Pass: $0 post --> post deployment of ceph in OC, networking, etc"
  echo "Pass: $0 instances --> deploy and customize instances"
  exit 1
fi

test "$(whoami)" != 'stack' && (echo "This must be run by the stack user on the
undercloud"; exit 1)

mon=$(grep mons $inventory_file -A 1 | tail -1 | awk {'print $1'})
if [[ -z $mon ]]; then
    echo "No host under [mons] in $inventory_file. Exiting. "
exit 1 
fi

if ! hash ansible 2>/dev/null; then
    echo "Cannot find ansible command. Exiting. "
exit 1 
fi

function preceph {
# Refresh helpful .ssh/config
python ../delleng-JS6/pilot/update_ssh_config.py

# -------------------------------------------------------
# COPY REPOS FOR BENCHMARKING
ansible -m copy -a "src=overcloud.repo dest=/etc/yum.repos.d/overcloud.repo mode=0744" -i $inventory_file all -b --ssh-common-args='-o StrictHostKeyChecking=no'
ansible -m user -a "name=root password='$6$rounds=656000$iZczA.CYkjM8GlTQ$XiiQQrjXg1OQ4QSkRymZncluuPh88pd8ZkOeyIPLZbFbpWhwm1VVwE4q5vLKhPzPOIeiFa4rLtDAXA7Tvk4yq.' update_password=always" -i $inventory_file all -b
#ansible -m copy -a "src=epel.repo dest=/etc/yum.repos.d/epel.repo mode=0744" -i hosts all -b
#ansible -m shell -a "yum -y install iperf3" -i hosts all -b
echo "Run Ceph-Ansible now."
}

function postceph {
# -------------------------------------------------------
# RESTART OPENSTACK SERVICES
echo "Fixing Keyring on non-osd systems for standalone CBT testing"
ansible -i $inventory_file clients -b -m shell -a "chmod 644 /etc/ceph/ceph.client.openstack.keyring"
echo "Restarting Glance (with Pacemaker)"
ansible all -i $mon\, -u heat-admin -b -m shell -a "pcs resource disable openstack-glance-api-clone"
ansible all -i $mon\, -u heat-admin -b -m shell -a "pcs status | grep -A 2 glance-api"
ansible all -i $mon\, -u heat-admin -b -m shell -a "pcs resource enable openstack-glance-api-clone"
ansible all -i $mon\, -u heat-admin -b -m shell -a "pcs status | grep -A 2 glance-api"
echo "Restarting Cinder (with Pacemaker)"
ansible all -i $mon\, -u heat-admin -b -m shell -a "pcs resource disable openstack-cinder-volume"
ansible all -i $mon\, -u heat-admin -b -m shell -a "pcs status | grep -A 2 openstack-cinder-volume"
ansible all -i $mon\, -u heat-admin -b -m shell -a "pcs resource enable openstack-cinder-volume"
ansible all -i $mon\, -u heat-admin -b -m shell -a "pcs status | grep -A 2 openstack-cinder-volume"
    
echo "Restarting Nova Compute everywhere"
ansible -i $inventory_file all:!mons -b -m shell -a "systemctl status openstack-nova-compute.service"
ansible -i $inventory_file all:!mons -b -m shell -a "systemctl restart openstack-nova-compute.service"
ansible -i $inventory_file all:!mons -b -m shell -a "systemctl status openstack-nova-compute.service"

if [ $1 = "converged" ]; then
    echo "Disabling Nova-Compute on R220s (with Systemd)"
    ansible -i $inventory_file clients -b -m shell -a "systemctl stop openstack-nova-compute.service"
    source ~/overcloudrc
    for i in {5..13}
    do
        nova service-disable overcloud-compute-$i.localdomain nova-compute
    done
    for i in {0..4}
    do
        nova service-enable overcloud-compute-$i.localdomain nova-compute
    done
elif [ $1 = "standalone" ]; then
    echo "Disabling Nova-Compute on all standalone RH Ceph nodes (with Systemd)"
    ansible -i $inventory_file osds -b -m shell -a "systemctl stop openstack-nova-compute.service"
    source ~/overcloudrc
    for i in {0..4}
    do
        nova service-disable overcloud-compute-$i.localdomain nova-compute
    done
    for i in {5..13}
    do
        nova service-enable overcloud-compute-$i.localdomain nova-compute
    done
else
    echo "Not disabling any of the compute nodes, as $1 was passed." 
fi
# -------------------------------------------------------
echo "The overcloud should be ready to use. Please test. "
}

function occustom {
echo "Creating Overcloud postdeployment stuff"
source ~/overcloudrc

#upload images
openstack image create --disk-format raw --container-format bare --copy-from http://refarch-coe.front.sepia.ceph.com/iso/rhel-guest-image-7.3-35.x86_64.raw --public rh73-raw
openstack image create --disk-format raw --container-format bare --copy-from http://refarch-coe.front.sepia.ceph.com/iso/cbtmaster.raw --public cbtmaster

# create new project/user/tenant

openstack user create redhat --password redhat --email redhat@example.com
openstack project create redhat-tenant
openstack role add --project redhat-tenant --user redhat _member_
tenantUser=$(openstack user list | awk '/redhat/ {print $2}')
tenant=$(openstack project list | awk '/redhat/ {print $2}')

# Quota updates
nova quota-update $tenant --instances 500 --cores 500 --ram 1228800 --floating-ips 60
cinder quota-update --volumes 500 --gigabytes 216000 $tenant
neutron quota-update --tenant_id $tenant --port 100000

# create custom flavor
openstack flavor create --public m1.cbt --id auto --ram 2048 --disk 20 --vcpus 4

# Create 100 iops cinder volume type for qos
cinder qos-create cbt-qos consumer="front-end" total_iops_sec=100 total_bytes_sec=41943040
tenantVolumeQosID=$(cinder qos-list | awk '/cbt-qos/ {print $2}')
cinder type-create cbt-type
tenantVolumeTypeID=$(cinder type-list | awk '/cbt-type/ {print $2}')
cinder qos-associate $tenantVolumeQosID $tenantVolumeTypeID
cinder qos-get-association $tenantVolumeQosID

# Security groups inbound exception
source ~/redhatovercloudrc
neutron security-group-rule-create --direction ingress --protocol icmp default
neutron security-group-rule-create --direction ingress --protocol tcp --port_range_min 22 --port_range_max 22 default

# Provider network (issues)
#source ~/overcloudrc
#neutron net-create --provider:physical_network floating --provider:network_type flat --shared provider
#neutron subnet-create --name provider_subnet --enable_dhcp=False --dns-nameserver 172.21.0.10  --allocation-pool=start=172.21.1.157,end=172.21.1.254 --gateway=172.21.15.254 provider 172.21.0.0/20

# Keypair creation as redhat user for SSH through floating ip
source ~/redhatovercloudrc
nova keypair-add dcain > ~/dcain.pem
chmod 600 ~/dcain.pem

# Tenant Network as redhat user
source ~/redhatovercloudrc
neutron net-create default
neutron subnet-create --name default_subnet --gateway 10.10.0.1 default 10.10.0.0/18 --dns-nameserver 172.21.0.10 --dns-nameserver 8.8.8.8 --allocation-pool start=10.10.0.5,end=10.10.63.254
neutron router-create router1
subnet_id=$(neutron subnet-list | awk ' /10.10./ {print $2 } ')
neutron router-interface-add router1 $subnet_id

# Floating IP network as admin user
source ~/overcloudrc
neutron net-create floating --router:external --provider:network_type flat --provider:physical_network floating
neutron subnet-create --name floating_subnet --enable_dhcp=False --allocation-pool=start=172.21.1.160,end=172.21.1.254 --gateway=172.21.15.254 floating 172.21.0.0/20
route_id=$(neutron router-list | awk ' /router1/ { print $2 } ')
ext_net_id=$(neutron net-list | awk ' /floating/ { print $2 } ')
neutron router-gateway-set $route_id $ext_net_id

# Floating IP allocate
source ~/redhatovercloudrc
for i in {1..53}
do
    nova floating-ip-create floating
done

# Create volumes from image, boot images
source ~/redhatovercloudrc
instancenum=1
for i in {161..214}
do
    cinder create --image cbtgold --name cbt$i --volume-type cbt-type 23
    bootvol=$(cinder list | awk ' /cbt'$i'/ {print $2} ')
    nova boot --flavor m1.cbt --key-name dcain --boot-volume $bootvol --nic net-name=default cbt$instancenum
    floatingIP=$(nova floating-ip-list | awk ' /172.21.1.'$i'/ {print $4} ')
    nova floating-ip-associate cbt$instancenum $floatingIP
    instancenum=$(( $instancenum + 1 ))
done

}

function instances {

# -------------------------------------------------------
# COPY REPOS FOR BENCHMARKING
ansible -m copy -a "src=overcloud.repo dest=/etc/yum.repos.d/overcloud.repo mode=0744" -i $instances_inventory_file all -b --ssh-common-args='-o StrictHostKeyChecking=no'
#ansible -m copy -a "src=epel.repo dest=/etc/yum.repos.d/epel.repo mode=0744" -i $instances_inventory_file all -b
#ansible -m shell -a "yum -y update" -i $instances_inventory_file all -b
echo "Customized Running Instances."
}


if [ $1 = "preceph" ]; then
    preceph
fi

if [ $1 = "converged" ]; then
    postceph converged
elif [ $1 = "standalone" ]; then
    postceph standalone
elif [ $1 = "all" ]; then
    postceph all
fi

if [ $1 = "post" ]; then
    occustom
fi

if [ $1 = "instances" ]; then
    instances
fi

exit 0
