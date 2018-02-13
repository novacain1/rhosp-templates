#!/bin/bash

subscription_manager_user="$1"
subscription_manager_password="$2"
subscription_manager_poolid="$3"

if [ "$#" -lt 2 ]; then
  echo "Usage: $0  <subscription manager user> <subscription manager password> [<subscription pool id>]"
  exit 1
fi

echo "## install libguestfs-tools"
cd ~/images
sudo yum install libguestfs-tools libvirt rhosp-director-images -y

export LIBGUESTFS_BACKEND=direct

echo "## Register the image with subscription manager & enable repos"
virt-customize -a overcloud-full.qcow2 --run-command "\
    subscription-manager register --username=${subscription_manager_user} --password=${subscription_manager_password}"

if [ -z "${subscription_manager_poolid}" ]; then
    subscription_manager_poolid=$(sudo subscription-manager list --available --matches='Red Hat OpenStack Platform, Self-Support (4 Sockets, NFR, Partner Only)' --pool-only|tail -n1)
    echo "Red Hat OpenStack Platform, Self-Support (4 Sockets, NFR, Partner Only): ${subscription_manager_poolid}"
fi

if [ -z "${subscription_manager_poolid}" ]; then
    echo "subscription_manager_poolid is empty."
    exit 1
fi

echo "## Add necessary Repos from CDN"
virt-customize -a overcloud-full.qcow2 \
    --run-command "subscription-manager attach --pool=${subscription_manager_poolid}" \
    --run-command "\
        subscription-manager repos '--disable=*' --enable=rhel-7-server-rpms \
            --enable=rhel-7-server-extras-rpms --enable=rhel-7-server-openstack-10-rpms"

echo "## Install OpenDaylight and update"
#running into problems updating, skipping for now 1-31-18 dcain
#virt-customize -v -x -a overcloud-full.qcow2 --install opendaylight --selinux-relabel --update
virt-customize -v -x -a overcloud-full.qcow2 --install opendaylight --selinux-relabel

echo "## Unregister from subscription manager"
virt-customize -a overcloud-full.qcow2 --run-command 'subscription-manager remove --all && subscription-manager unregister && subscription-manager clean'

echo "## Change the root password in the image"
virt-customize -a overcloud-full.qcow2 --root-password password:ILoveVCO!

echo "##upload the image to the overcloud"
openstack overcloud image upload --update-existing --image-path $HOME/images
openstack baremetal configure boot

echo "## Done updating the overcloud image"
