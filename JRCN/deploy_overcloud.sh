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
  -r ~/templates/roles_data_with_generic.yaml \
  -e ~/templates/network-environment.yaml \
  -e ~/templates/storage-environment.yaml \
  -e ~/templates/ips-from-pool-all.yaml \
  -e ~/templates/vco2.yaml \
  -e /usr/share/openstack-tripleo-heat-templates/environments/neutron-opendaylight-l3.yaml \
  --libvirt-type kvm \
  --timeout 120 \
  --control-scale 3 \
  --compute-scale 6 \
  --ceph-storage-scale 3 \
  --compute-flavor baremetal \
  --control-flavor baremetal \
  --ceph-storage-flavor baremetal \
  --stack vco2 \
  --ntp-server pool.ntp.org \
  --log-file overcloud_deployment.log
}

function updateRHOSP {
time yes "" | openstack overcloud update stack vco2 -i --templates \
  -r ~/templates/roles_data_with_generic.yaml \
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
