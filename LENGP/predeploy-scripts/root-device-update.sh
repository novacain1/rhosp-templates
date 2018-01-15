#!/bin/bash

# -------------------------------------------------------
# SAFETY CHECKS
test "$(whoami)" != 'stack' && (echo "This must be run by the stack user on the
undercloud"; exit 1)

ironic node-update sr630-1 remove properties/root_device
ironic node-update sr630-2 remove properties/root_device
ironic node-update sr630-3 remove properties/root_device

openstack overcloud node configure sr630-1 --root-device=sdb
openstack overcloud node configure sr630-2 --root-device=sdb
openstack overcloud node configure sr630-3 --root-device=sdb
