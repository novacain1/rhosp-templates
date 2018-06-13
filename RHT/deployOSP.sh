#!/bin/bash -x

# -------------------------------------------------------
STACKNAME=rht

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
  -e ~/templates/rht.yaml \
  -e ~/templates/network-environment.yaml \
  -e ~/templates/overcloud_images.yaml \
  -t 120 \
  --compute-flavor compute \
  --control-flavor control \
  --ceph-storage-flavor ceph-storage \
  --stack $STACKNAME
}

function updateRHOSP {
time yes "" | openstack overcloud update stack overcloud -i --templates \
  -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
  -e ~/templates/rht.yaml \
  -e ~/templates/network-environment.yaml \
  -e ~/templates/overcloud_images.yaml
}


if [ $1 = "deploy" ]; then
    deployRHOSP
fi

if [ $1 = "update" ]; then
    updateRHOSP
fi

exit 0
