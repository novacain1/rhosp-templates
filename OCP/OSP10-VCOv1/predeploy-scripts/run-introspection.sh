for node in $(openstack baremetal node list -c UUID -f value) ; do openstack baremetal node manage $node ; done
openstack overcloud node introspect --all-manageable --provide

#openstack baremetal node manage ocp1
#openstack baremetal node manage ocp2
#openstack baremetal node manage ocp3
#openstack baremetal node manage ocp6
#openstack baremetal node manage ocp8
#openstack baremetal node manage ocp9
#openstack baremetal node manage ocp10
#openstack baremetal node manage ocp11
#openstack baremetal node manage ocp12
#openstack baremetal node manage gp4
#openstack baremetal node manage gp5
#openstack baremetal node manage gp6

#openstack overcloud node introspect ocp1 --provide
#openstack overcloud node introspect ocp2 --provide
#openstack overcloud node introspect ocp3 --provide
#openstack overcloud node introspect ocp6 --provide
#openstack overcloud node introspect ocp8 --provide
#openstack overcloud node introspect ocp9 --provide
#openstack overcloud node introspect ocp10 --provide
#openstack overcloud node introspect ocp11 --provide
#openstack overcloud node introspect ocp12 --provide
#openstack overcloud node introspect gp4 --provide
#openstack overcloud node introspect gp5 --provide
#openstack overcloud node introspect gp6 --provide

