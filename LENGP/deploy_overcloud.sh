#!/bin/bash -x
#<2018-01-10 dcain>

# -------------------------------------------------------
# RHOSP deploy/update script for MWC Demo
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
  -e ~/templates/storage-environment.yaml \
  -e ~/templates/ips-from-pool-all.yaml \
  -e ~/templates/rhlen-mwc.yaml \
  --timeout 100 \
  --control-scale 1 \
  --compute-scale 2 \
  --compute-flavor compute \
  --control-flavor control \
  --stack rhlen-mwc \
  --ntp-server pool.ntp.org \
  --log-file overcloud_deployment.log \
  --neutron-network-type vxlan \
  --neutron-tunnel-types vxlan
}

function updateRHOSP {
time yes "" | openstack overcloud update stack overcloud -i --templates \
  -e ~/templates/network-environment.yaml \
  -e ~/templates/storage-environment.yaml \
  -e ~/templates/ips-from-pool-all.yaml \
  -e ~/templates/rhlen-mwc.yaml
}

if [ $1 = "deploy" ]; then
  deployRHOSP
elif  [ $1 = "update" ]; then
  updateRHOSP
fi

exit 0
