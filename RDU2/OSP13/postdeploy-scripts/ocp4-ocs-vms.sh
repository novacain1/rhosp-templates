#!/bin/bash

function create {
source ~/rdurc

openstack port create --network baremetal --project redhat-tenant --fixed-ip subnet=baremetal-subnet,ip-address=192.168.68.15 --mac-address fa:16:3e:13:1a:5a rdu-ocs4-0
openstack port create --network baremetal --project redhat-tenant --fixed-ip subnet=baremetal-subnet,ip-address=192.168.68.16 --mac-address fa:16:3e:13:1a:5b rdu-ocs4-1
openstack port create --network baremetal --project redhat-tenant --fixed-ip subnet=baremetal-subnet,ip-address=192.168.68.17 --mac-address fa:16:3e:13:1a:5c rdu-ocs4-2

source ~/redhatrc

openstack volume create --size 1000 rdu-ocs4-0-sdb
openstack volume create --size 1000 rdu-ocs4-1-sdb
openstack volume create --size 1000 rdu-ocs4-2-sdb
openstack volume create --size 10 rdu-ocs4-0-sdc
openstack volume create --size 10 rdu-ocs4-1-sdc
openstack volume create --size 10 rdu-ocs4-2-sdc

openstack server create --image pxeboot --flavor m1.ocp4ocs --key-name dcain --port rdu-ocs4-0 rdu-ocs4-0
openstack server create --image pxeboot --flavor m1.ocp4ocs --key-name dcain --port rdu-ocs4-1 rdu-ocs4-1
openstack server create --image pxeboot --flavor m1.ocp4ocs --key-name dcain --port rdu-ocs4-2 rdu-ocs4-2

openstack server add volume rdu-ocs4-0 rdu-ocs4-0-sdb
openstack server add volume rdu-ocs4-0 rdu-ocs4-0-sdc
openstack server add volume rdu-ocs4-1 rdu-ocs4-1-sdb
openstack server add volume rdu-ocs4-1 rdu-ocs4-1-sdc
openstack server add volume rdu-ocs4-2 rdu-ocs4-2-sdb
openstack server add volume rdu-ocs4-2 rdu-ocs4-2-sdc
}

function destroy {
source ~/redhatrc

openstack server delete rdu-ocs4-0
openstack server delete rdu-ocs4-1
openstack server delete rdu-ocs4-2

openstack volume delete rdu-ocs4-0-sdb
openstack volume delete rdu-ocs4-0-sdc
openstack volume delete rdu-ocs4-1-sdb
openstack volume delete rdu-ocs4-1-sdc
openstack volume delete rdu-ocs4-2-sdb
openstack volume delete rdu-ocs4-2-sdc

openstack port delete rdu-ocs4-0
openstack port delete rdu-ocs4-1
openstack port delete rdu-ocs4-2

}

if [ $1 = "create" ]; then
    create
fi

if [ $1 = "destroy" ]; then
    destroy
fi

exit 0
