#!/bin/bash -x

# -------------------------------------------------------
# SAFETY CHECKS
if [ "$#" -lt 1 ]; then
  echo "Pass: $0 regular --> regular assignment sepia lab"
  echo "Pass: $0 generic --> generic assignment sepia lab"
  exit 1
fi

test "$(whoami)" != 'stack' && (echo "This must be run by the stack user on the
undercloud"; exit 1)

function regularOvercloudSet {
ironic node-update r630-01 replace properties/capabilities='node:controller-0,cpu_aes:true,cpu_hugepages:true,cpu_txt:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r630-02 replace properties/capabilities='node:controller-1,cpu_aes:true,cpu_hugepages:true,cpu_txt:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r630-03 replace properties/capabilities='node:controller-2,cpu_aes:true,cpu_hugepages:true,cpu_txt:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r730xd-01 replace properties/capabilities='node:cephstorage-0,cpu_aes:true,cpu_hugepages:true,cpu_txt:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r730xd-02 replace properties/capabilities='node:cephstorage-1,cpu_aes:true,cpu_hugepages:true,cpu_txt:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r730xd-03 replace properties/capabilities='node:cephstorage-2,cpu_aes:true,cpu_hugepages:true,cpu_txt:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r730xd-04 replace properties/capabilities='node:cephstorage-3,cpu_aes:true,cpu_hugepages:true,cpu_txt:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r730xd-05 replace properties/capabilities='node:cephstorage-4,cpu_aes:true,cpu_hugepages:true,cpu_txt:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r220-02 replace properties/capabilities='node:compute-0,cpu_hugepages:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r220-03 replace properties/capabilities='node:compute-1,cpu_hugepages:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r220-04 replace properties/capabilities='node:compute-2,cpu_hugepages:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r220-05 replace properties/capabilities='node:compute-3,cpu_hugepages:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r220-06 replace properties/capabilities='node:compute-4,cpu_hugepages:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r220-07 replace properties/capabilities='node:compute-5,cpu_hugepages:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r220-08 replace properties/capabilities='node:compute-6,cpu_hugepages:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r220-09 replace properties/capabilities='node:compute-7,cpu_hugepages:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r220-10 replace properties/capabilities='node:compute-8,cpu_hugepages:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
}

function genericOvercloudSet {
ironic node-update r630-01 replace properties/capabilities='node:generic-0,cpu_aes:true,cpu_hugepages:true,cpu_txt:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r630-02 replace properties/capabilities='node:generic-1,cpu_aes:true,cpu_hugepages:true,cpu_txt:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r630-03 replace properties/capabilities='node:generic-2,cpu_aes:true,cpu_hugepages:true,cpu_txt:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r730xd-01 replace properties/capabilities='node:generic-3,cpu_aes:true,cpu_hugepages:true,cpu_txt:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r730xd-02 replace properties/capabilities='node:generic-4,cpu_aes:true,cpu_hugepages:true,cpu_txt:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r730xd-03 replace properties/capabilities='node:generic-5,cpu_aes:true,cpu_hugepages:true,cpu_txt:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r730xd-04 replace properties/capabilities='node:generic-6,cpu_aes:true,cpu_hugepages:true,cpu_txt:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r730xd-05 replace properties/capabilities='node:generic-7,cpu_aes:true,cpu_hugepages:true,cpu_txt:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r220-02 replace properties/capabilities='node:genericr220-0,cpu_hugepages:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r220-03 replace properties/capabilities='node:genericr220-1,cpu_hugepages:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r220-04 replace properties/capabilities='node:genericr220-2,cpu_hugepages:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r220-05 replace properties/capabilities='node:genericr220-3,cpu_hugepages:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r220-06 replace properties/capabilities='node:genericr220-4,cpu_hugepages:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r220-07 replace properties/capabilities='node:genericr220-5,cpu_hugepages:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r220-08 replace properties/capabilities='node:genericr220-6,cpu_hugepages:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r220-09 replace properties/capabilities='node:genericr220-7,cpu_hugepages:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
ironic node-update r220-10 replace properties/capabilities='node:genericr220-8,cpu_hugepages:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
}


if [ $1 = "regular" ]; then
    regularOvercloudSet
fi

if [ $1 = "generic" ]; then
    genericOvercloudSet
fi

exit 0

#ironic node-update r630-01 replace properties/capabilities='profile:control,node:controller-0,cpu_aes:true,cpu_hugepages:true,cpu_txt:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
#ironic node-update r630-02 replace properties/capabilities='profile:control,node:controller-1,cpu_aes:true,cpu_hugepages:true,cpu_txt:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
#ironic node-update r630-03 replace properties/capabilities='profile:control,node:controller-2,cpu_aes:true,cpu_hugepages:true,cpu_txt:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
#ironic node-update r730xd-01 replace properties/capabilities='profile:ceph-storage,node:ceph-storage-0,cpu_aes:true,cpu_hugepages:true,cpu_txt:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
#ironic node-update r730xd-02 replace properties/capabilities='profile:ceph-storage,node:ceph-storage-1,cpu_aes:true,cpu_hugepages:true,cpu_txt:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
#ironic node-update r730xd-03 replace properties/capabilities='profile:ceph-storage,node:ceph-storage-2,cpu_aes:true,cpu_hugepages:true,cpu_txt:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
#ironic node-update r730xd-04 replace properties/capabilities='profile:ceph-storage,node:ceph-storage-3,cpu_aes:true,cpu_hugepages:true,cpu_txt:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
#ironic node-update r730xd-05 replace properties/capabilities='profile:ceph-storage,node:ceph-storage-4,cpu_aes:true,cpu_hugepages:true,cpu_txt:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
#ironic node-update r220-02 replace properties/capabilities='profile:compute,node:compute-0,cpu_hugepages:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
#ironic node-update r220-03 replace properties/capabilities='profile:compute,node:compute-1,cpu_hugepages:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
#ironic node-update r220-04 replace properties/capabilities='profile:compute,node:compute-2,cpu_hugepages:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
#ironic node-update r220-05 replace properties/capabilities='profile:compute,node:compute-3,cpu_hugepages:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
#ironic node-update r220-06 replace properties/capabilities='profile:compute,node:compute-4,cpu_hugepages:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
#ironic node-update r220-07 replace properties/capabilities='profile:compute,node:compute-5,cpu_hugepages:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
#ironic node-update r220-08 replace properties/capabilities='profile:compute,node:compute-6,cpu_hugepages:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
#ironic node-update r220-09 replace properties/capabilities='profile:compute,node:compute-7,cpu_hugepages:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
#ironic node-update r220-10 replace properties/capabilities='profile:compute,node:compute-8,cpu_hugepages:true,boot_option:local,cpu_vt:true,cpu_hugepages_1g:true'
