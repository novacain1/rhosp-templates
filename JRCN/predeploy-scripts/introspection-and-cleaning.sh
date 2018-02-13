#!/bin/bash -x

# -------------------------------------------------------
# SAFETY CHECKS
if [ "$#" -lt 1 ]; then
  echo "Pass: $0 introspect --> do all introspection"
  echo "Pass: $0 clean --> clean all nodes"
  exit 1
fi

test "$(whoami)" != 'stack' && (echo "This must be run by the stack user on the
undercloud"; exit 1)

function introspect {
#do introspection of all nodes to get hardware related information
for node in $(openstack baremetal node list -c UUID -f value) ; do 
  openstack baremetal node manage $node
done

openstack overcloud node introspect --all-manageable --provide
}

function clean {
#lazily clean nodes using ironic's native cleaning function, clean metadata only
for node in $(openstack baremetal node list -c UUID -f value) ; do 
  ironic node-set-provision-state $node manage
done

for node in $(openstack baremetal node list -c UUID -f value) ; do 
  ironic --ironic-api-version 1.15 node-set-provision-state $node clean --clean-steps '[{"interface": "deploy", "step": "erase_devices_metadata"}]'
done

sleep 30m

for node in $(openstack baremetal node list -c UUID -f value) ; do 
  ironic node-set-provision-state $node provide
done

#openstack overcloud node provide --all-manageable
}

if [ $1 = "introspect" ]; then
    introspect
fi

if [ $1 = "clean" ]; then
    clean
fi

exit 0
