#!/bin/bash -x

# -------------------------------------------------------
STACKNAME=sepia

# SAFETY CHECKS
if [ "$#" -lt 1 ]; then
  echo "Pass: $0 deploy --> deploy RHOSP"
  echo "Pass: $0 update --> update RHOSP packages"
  exit 1
fi

test "$(whoami)" != 'stack' && (echo "This must be run by the stack user on the
undercloud"; exit 1)

function deployRHOSP {
time openstack overcloud deploy --templates \
  -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
  -r ~/templates/roles_data_with_generic.yaml \
  -e ~/templates/network-environment.yaml \
  -e ~/templates/storage-environment.yaml \
  -e ~/templates/ips-from-pool-all.yaml \
  -e ~/templates/refarch.yaml \
  -t 120 \
  --compute-flavor baremetal \
  --control-flavor baremetal \
  --ceph-storage-flavor baremetal \
  --stack $STACKNAME
}

function updateRHOSP {
time yes "" | openstack overcloud update stack overcloud -i --templates \
  -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
  -r ~/templates/roles_data_with_generic.yaml \
  -e ~/templates/network-environment.yaml \
  -e ~/templates/storage-environment.yaml \
  -e ~/templates/ips-from-pool-all.yaml \
  -e ~/templates/refarch.yaml
}


if [ $1 = "deploy" ]; then
    deployRHOSP
fi

if [ $1 = "update" ]; then
    updateRHOSP
fi

exit 0
