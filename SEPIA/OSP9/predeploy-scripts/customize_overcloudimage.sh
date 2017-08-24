#!/bin/bash

subscription_manager_user="$1"
subscription_manager_pass="$2"
subscription_manager_poolid="$3"

if [ "$#" -lt 2 ]; then
  echo "Usage: $0  <subscription manager user> <subscription manager password> [<subscription pool id>]"
  exit 1
fi

echo "## install libguestfs-tools"
cd ~/images
sudo yum install libguestfs-tools -y

export LIBGUESTFS_BACKEND=direct

echo "## Register the image with subscription manager & enable repos"
virt-customize -a overcloud-full.qcow2 --run-command "\
    subscription-manager register --username=${subscription_manager_user} --password=${subscription_manager_pass}"

if [ -z "${subscription_manager_poolid}" ]; then
    subscription_manager_poolid=$(sudo subscription-manager list --available --matches='Red Hat Ceph Storage' --pool-only|tail -n1)
    echo "Red Hat Ceph Storage pool: ${subscription_manager_poolid}"
fi

if [ -z "${subscription_manager_poolid}" ]; then
    echo "subscription_manager_poolid is empty."
    exit 1
fi

echo "## Remove Ceph 1.3"
virt-customize -a overcloud-full.qcow2 --run-command "\
    yum -y remove ceph ceph-common ceph-mon ceph-osd ceph-radosgw"

echo "## Add necessary Repos from CDN"
virt-customize -a overcloud-full.qcow2 \
    --run-command "subscription-manager attach --pool=${subscription_manager_poolid}" \
    --run-command "\
        subscription-manager repos '--disable=*' --enable=rhel-7-server-rpms \
            --enable=rhel-7-server-rhceph-2-mon-rpms --enable=rhel-7-server-rhceph-2-osd-rpms \
            --enable=rhel-7-server-rhceph-2-tools-rpms"

echo "## Install Ceph 2.0 instead"
virt-customize -v -x -m 2000 -a overcloud-full.qcow2 --install ceph-* --selinux-relabel

#echo "## Unregister from subscription manager"
virt-customize -a overcloud-full.qcow2 --run-command 'subscription-manager remove --all' --run-command 'subscription-manager unregister'

# upload the image to the overcloud
openstack overcloud image upload --update-existing --image-path $HOME/images
openstack baremetal configure boot

echo "## Done updating the overcloud image"
