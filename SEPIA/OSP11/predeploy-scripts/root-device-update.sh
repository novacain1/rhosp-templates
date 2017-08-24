#!/bin/bash

# -------------------------------------------------------
# SAFETY CHECKS
test "$(whoami)" != 'stack' && (echo "This must be run by the stack user on the
undercloud"; exit 1)

ironic node-update r630-01 remove properties/root_device
ironic node-update r630-02 remove properties/root_device
ironic node-update r630-03 remove properties/root_device
ironic node-update r730xd-01 remove properties/root_device
ironic node-update r730xd-02 remove properties/root_device
ironic node-update r730xd-03 remove properties/root_device
ironic node-update r730xd-04 remove properties/root_device
ironic node-update r730xd-05 remove properties/root_device
ironic node-update r220-02 remove properties/root_device
ironic node-update r220-03 remove properties/root_device
ironic node-update r220-04 remove properties/root_device
ironic node-update r220-05 remove properties/root_device
ironic node-update r220-06 remove properties/root_device
ironic node-update r220-07 remove properties/root_device
ironic node-update r220-08 remove properties/root_device
ironic node-update r220-09 remove properties/root_device
ironic node-update r220-10 remove properties/root_device

openstack overcloud node configure r630-01 --root-device=smallest
openstack overcloud node configure r630-02 --root-device=smallest
openstack overcloud node configure r630-03 --root-device=smallest
openstack overcloud node configure r730xd-01 --root-device=smallest
openstack overcloud node configure r730xd-02 --root-device=smallest
openstack overcloud node configure r730xd-03 --root-device=smallest
openstack overcloud node configure r730xd-04 --root-device=smallest
openstack overcloud node configure r730xd-05 --root-device=smallest
#ironic node-update r730xd-01 add properties/root_device='{"size": 465}'
#ironic node-update r730xd-02 add properties/root_device='{"size": 465}'
#ironic node-update r730xd-03 add properties/root_device='{"size": 465}'
#ironic node-update r730xd-04 add properties/root_device='{"size": 465}'
#ironic node-update r730xd-05 add properties/root_device='{"size": 465}'
#openstack overcloud node configure r730xd-01 --root-device=
#openstack overcloud node configure r730xd-02 --root-device=
#openstack overcloud node configure r730xd-03 --root-device=
#openstack overcloud node configure r730xd-04 --root-device=
#openstack overcloud node configure r730xd-05 --root-device=
openstack overcloud node configure r220-02 --root-device=smallest
openstack overcloud node configure r220-03 --root-device=smallest
openstack overcloud node configure r220-04 --root-device=smallest
openstack overcloud node configure r220-05 --root-device=smallest
openstack overcloud node configure r220-06 --root-device=smallest
openstack overcloud node configure r220-07 --root-device=smallest
openstack overcloud node configure r220-08 --root-device=smallest
openstack overcloud node configure r220-09 --root-device=smallest
openstack overcloud node configure r220-10 --root-device=smallest
