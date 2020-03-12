#!/bin/bash

# -------------------------------------------------------
# SAFETY CHECKS
test "$(whoami)" != 'stack' && (echo "This must be run by the stack user on the
undercloud"; exit 1)

#ironic node-update b200-01 remove properties/root_device
#ironic node-update b200-02 remove properties/root_device
#ironic node-update b200-03 remove properties/root_device
#ironic node-update b200-04 remove properties/root_device
ironic node-update b200-05 remove properties/root_device
ironic node-update b200-06 remove properties/root_device
ironic node-update b200-07 remove properties/root_device
ironic node-update c240-01 remove properties/root_device
ironic node-update c240-02 remove properties/root_device
ironic node-update c240-03 remove properties/root_device
ironic node-update c240-04 remove properties/root_device

#openstack overcloud node configure b200-01 --root-device=sda
#openstack overcloud node configure b200-02 --root-device=sda
#openstack overcloud node configure b200-03 --root-device=sda
#openstack overcloud node configure b200-04 --root-device=sda
openstack overcloud node configure b200-05 --root-device=sda
openstack overcloud node configure b200-06 --root-device=sda
openstack overcloud node configure b200-07 --root-device=sda
openstack overcloud node configure c240-01 --root-device=sda
openstack overcloud node configure c240-02 --root-device=sda
openstack overcloud node configure c240-03 --root-device=sda
openstack overcloud node configure c240-04 --root-device=sda
