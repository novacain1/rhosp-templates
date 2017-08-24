#!/bin/bash -x

# -------------------------------------------------------
# SAFETY CHECKS
if [ "$#" -lt 1 ]; then
  echo "Pass: $0 deploy --> deploy RHOSP"
  echo "Pass: $0 update --> update RHOSP packages"
  exit 1
fi

test "$(whoami)" != 'stack' && (echo "This must be run by the stack user on the
undercloud"; exit 1)

function deployRHOSP {
openstack overcloud deploy --templates \
  -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
  -e ~/templates/refarch.yaml \
  -e ~/templates/network-environment.yaml \
  -e ~/templates/environments/puppet-ceph-external.yaml \
  -e ~/templates/nic-mappings.yaml \
  -e ~/templates/ips-from-pool-all.yaml \
  -t 120 \
  --control-scale 3 \
  --compute-scale 14 \
  --ceph-storage-scale 0 \
  --swift-storage-scale 0 \
  --block-storage-scale 0 \
  --compute-flavor compute \
  --control-flavor control \
  --ceph-storage-flavor ceph-storage \
  --swift-storage-flavor swift-storage \
  --block-storage-flavor block-storage \
  --ntp-server pool.ntp.org \
  --neutron-network-type vxlan \
  --neutron-tunnel-types vxlan \
}

function updateRHOSP {
time yes "" | openstack overcloud update stack overcloud -i --templates \
  -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
  -e ~/templates/refarch.yaml \
  -e ~/templates/network-environment.yaml \
  -e ~/templates/environments/puppet-ceph-external.yaml \
  -e ~/templates/nic-mappings.yaml \
  -e ~/templates/ips-from-pool-all.yaml
}


if [ $1 = "deploy" ]; then
    deployRHOSP
fi

if [ $1 = "update" ]; then
    updateRHOSP
fi

exit 0
