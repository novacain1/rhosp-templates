#!/bin/bash -x
#<2017-11-21 dcain>

# -------------------------------------------------------
# OSP10 deploy/update script for ETSI Plugfest #2
# environment in RTP, NC.
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
  -e ~/templates/ips-from-pool-all.yaml \
  -e ~/templates/storage-environment.yaml \
  -e /usr/share/openstack-tripleo-heat-templates/environments/ceph-radosgw.yaml \
  -e ~/templates/rhlen-etsi.yaml \
  -t 120 \
  --control-scale 3 \
  --compute-scale 5 \
  --ceph-storage-scale 4 \
  --compute-flavor compute \
  --control-flavor control \
  --ceph-storage-flavor ceph-storage \
  --stack rhlen-etsi \
  --ntp-server pool.ntp.org \
  --neutron-network-type vxlan \
  --neutron-tunnel-types vxlan
}

function updateRHOSP {
time yes "" | openstack overcloud update stack overcloud -i --templates \
  -e ~/templates/ips-from-pool-all.yaml \
  -e ~/templates/network-environment.yaml \
  -e ~/templates/storage-environment.yaml \
  -e /usr/share/openstack-tripleo-heat-templates/environments/ceph-radosgw.yaml \
  -e ~/templates/rhlen-etsi.yaml
}

if [ $1 = "deploy" ]; then
  deployRHOSP
elif  [ $1 = "update" ]; then
  updateRHOSP
fi

exit 0
