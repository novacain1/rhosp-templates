#!/bin/bash -x

# -------------------------------------------------------
STACKNAME=rdu

# SAFETY CHECKS
if [ "$#" -lt 1 ]; then
  echo "Pass: $0 deploy --> deploy RHOSP"
  echo "Pass: $0 updateUC1 --> update RHOSP undercloud, then reboot"
  echo "Pass: $0 updateUC2 --> update RHOSP undercloud (after reboot)"
  echo "Pass: $0 updateOC --> update RHOSP overcloud"
  exit 1
fi

test "$(whoami)" != 'stack' && (echo "This must be run by the stack user on the
undercloud"; exit 1)

function deployRHOSP {
time openstack overcloud deploy \
  --templates /usr/share/openstack-tripleo-heat-templates \
  -n /home/stack/templates/network_data.yaml \
  -r /home/stack/templates/roles_data.yaml \
  -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
  -p /usr/share/openstack-tripleo-heat-templates/plan-samples/plan-environment-derived-params.yaml \
  -e /usr/share/openstack-tripleo-heat-templates/environments/ceph-ansible/ceph-ansible.yaml \
  -e /usr/share/openstack-tripleo-heat-templates/environments/ceph-ansible/ceph-rgw.yaml \
  -e /usr/share/openstack-tripleo-heat-templates/environments/services-docker/ironic.yaml \
  -e /usr/share/openstack-tripleo-heat-templates/environments/services-docker/octavia.yaml \
  -e ~/environments/20-network-environment.yaml \
  -e ~/environments/25-scheduler-hints-env.yaml \
  -e ~/environments/30-ips-from-pool-all.yaml \
  -e ~/environments/35-ceph-config.yaml \
  -e ~/environments/40-ironic-baremetal.yaml \
  -e ~/environments/50-public_vip.yaml \
  -e ~/environments/99-rhosp-misc.yaml \
  -e ~/templates/overcloud_images.yaml \
  --log-file ~/deployment.log \
  --stack $STACKNAME \
  --timeout 120 \
  --verbose
}

function updateUC1 {
echo "Wiping old IPA images."
openstack image list | awk '$2 && $2 != "ID" {print $2}' | xargs -n1 openstack image delete

sudo yum -y update python-tripleoclient
time openstack undercloud upgrade
echo "Reboot the undercloud to update the operating system's kernel and other system packages."
}

function updateUC2 {
rm -rf  ~/images/*
cd ~/images
for i in /usr/share/rhosp-director-images/overcloud-full-latest-13.0.tar /usr/share/rhosp-director-images/ironic-python-agent-latest-13.0.tar; do tar -xvf $i; done
cd ~

time openstack overcloud image upload --image-path /home/stack/images
openstack overcloud node configure $(openstack baremetal node list -c UUID -f value)

openstack image list
ls -l /httpboot
echo "Done updating the undercloud."
}

function updateOC {
openstack overcloud update prepare --templates \
  -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
  -p /usr/share/openstack-tripleo-heat-templates/plan-samples/plan-environment-derived-params.yaml \
  -e /usr/share/openstack-tripleo-heat-templates/environments/ceph-ansible/ceph-ansible.yaml \
  -e ~/templates/overcloud_images.yaml \
  --environment-directory ~/environments \
  --stack rdu

openstack overcloud update run --nodes Controller --stack rdu
openstack overcloud update run --nodes ComputeHCI --stack rdu

openstack overcloud ceph-upgrade run --templates \
  -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
  -p /usr/share/openstack-tripleo-heat-templates/plan-samples/plan-environment-derived-params.yaml \
  -e /usr/share/openstack-tripleo-heat-templates/environments/ceph-ansible/ceph-ansible.yaml \
  -e ~/templates/overcloud_images.yaml \
  --environment-directory ~/environments

time openstack overcloud update converge --templates \
  -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
  -p /usr/share/openstack-tripleo-heat-templates/plan-samples/plan-environment-derived-params.yaml \
  -e /usr/share/openstack-tripleo-heat-templates/environments/ceph-ansible/ceph-ansible.yaml \
  -e ~/templates/overcloud_images.yaml \
  --environment-directory ~/environments

echo "Update complete."
}


if [ $1 = "deploy" ]; then
    deployRHOSP
fi

if [ $1 = "updateUC1" ]; then
    updateUC1
fi

if [ $1 = "updateUC2" ]; then
    updateUC2
fi

if [ $1 = "updateOC" ]; then
    updateOC
fi

exit 0
