#!/bin/bash

# -------------------------------------------------------
# SAFETY CHECKS
test "$(whoami)" != 'stack' && (echo "This must be run by the stack user on the
undercloud"; exit 1)

ironic node-update ocp1 remove properties/root_device
ironic node-update ocp2 remove properties/root_device
ironic node-update ocp3 remove properties/root_device
ironic node-update ocp4 remove properties/root_device
ironic node-update ocp5 remove properties/root_device
ironic node-update ocp6 remove properties/root_device
ironic node-update ocp7 remove properties/root_device
ironic node-update ocp8 remove properties/root_device
ironic node-update ocp9 remove properties/root_device
ironic node-update ocp10 remove properties/root_device
ironic node-update ocp11 remove properties/root_device
ironic node-update ocp12 remove properties/root_device

openstack overcloud node configure ocp1 --root-device=smallest
openstack overcloud node configure ocp2 --root-device=smallest
openstack overcloud node configure ocp3 --root-device=smallest
openstack overcloud node configure ocp4 --root-device=largest
openstack overcloud node configure ocp5 --root-device=largest
openstack overcloud node configure ocp6 --root-device=largest
openstack overcloud node configure ocp7 --root-device=largest
openstack overcloud node configure ocp8 --root-device=largest
openstack overcloud node configure ocp9 --root-device=largest
openstack overcloud node configure ocp10 --root-device=largest
openstack overcloud node configure ocp11 --root-device=largest
openstack overcloud node configure ocp12 --root-device=largest
