#!/bin/bash -x
#<2018-01-27 dcain>

# -------------------------------------------------------
# RHOSP deploy/update script for VCOv2 Demo
# environment in Santa Clara, CA.
# -------------------------------------------------------

# -------------------------------------------------------
# SAFETY CHECKS
if [ "$#" -lt 1 ]; then
  echo "Pass: $0 deploy --> deploy RHOSP"
  echo "Pass: $0 update --> update RHOSP packages"
  exit 1
fi

test "$(whoami)" != 'stack' && (echo "This must be run by the stack user on the undercloud"; exit 1)

function deployRHOSP {
time openstack overcloud deploy --templates \
  -e ~/templates/network-environment.yaml \
  -e ~/templates/storage-environment.yaml \
  -e ~/templates/ips-from-pool-all.yaml \
  -e ~/templates/vco2.yaml \
  -e /usr/share/openstack-tripleo-heat-templates/environments/neutron-opendaylight-l3.yaml \
  --timeout 120 \
  --control-scale 3 \
  --compute-scale 4 \
  --ceph-storage-scale 3 \
  --compute-flavor compute \
  --control-flavor control \
  --ceph-storage-flavor ceph-storage \
  --stack vco2 \
  --ntp-server pool.ntp.org \
  --log-file overcloud_deployment.log
}

function updateRHOSP {
time yes "" | openstack overcloud update stack vco2 -i --templates \
  -e ~/templates/network-environment.yaml \
  -e ~/templates/storage-environment.yaml \
  -e ~/templates/ips-from-pool-all.yaml \
  -e ~/templates/vco2.yaml \
  -e /usr/share/openstack-tripleo-heat-templates/environments/neutron-opendaylight-l3.yaml
}

if [ $1 = "deploy" ]; then
  deployRHOSP
elif  [ $1 = "update" ]; then
  updateRHOSP
fi

exit 0
