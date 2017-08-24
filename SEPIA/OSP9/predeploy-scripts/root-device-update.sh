#!/bin/bash

# -------------------------------------------------------
# SAFETY CHECKS
test "$(whoami)" != 'stack' && (echo "This must be run by the stack user on the
undercloud"; exit 1)

ironic node-update r730xd-01 add properties/root_device='{"size": 465}'
ironic node-update r730xd-02 add properties/root_device='{"size": 465}'
ironic node-update r730xd-03 add properties/root_device='{"size": 465}'
ironic node-update r730xd-04 add properties/root_device='{"size": 465}'
ironic node-update r730xd-05 add properties/root_device='{"size": 465}'
