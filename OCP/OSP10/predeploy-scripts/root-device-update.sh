#!/bin/bash

# -------------------------------------------------------
# SAFETY CHECKS
test "$(whoami)" != 'stack' && (echo "This must be run by the stack user on the
undercloud"; exit 1)

ironic node-update ocp1 remove properties/root_device
ironic node-update ocp2 remove properties/root_device
ironic node-update ocp3 remove properties/root_device
ironic node-update ocp6 remove properties/root_device
ironic node-update ocp8 remove properties/root_device
ironic node-update ocp9 remove properties/root_device
ironic node-update ocp10 remove properties/root_device
ironic node-update ocp11 remove properties/root_device
ironic node-update ocp12 remove properties/root_device
ironic node-update gp1 remove properties/root_device
ironic node-update gp2 remove properties/root_device
ironic node-update gp3 remove properties/root_device
ironic node-update gp4 remove properties/root_device
ironic node-update gp5 remove properties/root_device
ironic node-update gp6 remove properties/root_device

openstack overcloud node configure ocp1 --root-device=smallest
openstack overcloud node configure ocp2 --root-device=smallest
openstack overcloud node configure ocp3 --root-device=smallest
openstack overcloud node configure ocp6 --root-device=smallest
openstack overcloud node configure ocp8 --root-device=smallest
openstack overcloud node configure ocp9 --root-device=smallest
openstack overcloud node configure ocp10 --root-device=smallest
openstack overcloud node configure ocp11 --root-device=smallest
openstack overcloud node configure ocp12 --root-device=smallest
openstack overcloud node configure gp1 --root-device=sdf
openstack overcloud node configure gp2 --root-device=sdg
openstack overcloud node configure gp3 --root-device=sdf
openstack overcloud node configure gp4 --root-device=sdg
openstack overcloud node configure gp5 --root-device=sdg
openstack overcloud node configure gp6 --root-device=sdg
