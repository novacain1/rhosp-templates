#!/bin/bash

source ~/vco2rc

USERS="f5"


for user in ${USERS}; do
  openstack user create ${user} --password ${user} --email ${user}@redhat.vco2.lab.local
  openstack project create ${user}
  openstack role add --project ${user} --user ${user} _member_
  tenantUser=$(openstack user show ${user} -f value -c id)
  tenant=$(openstack project show ${user} -f value -c id)

  #quota updates
  nova quota-update $tenant --instances 20 --cores 20 --ram 64000
  cinder quota-update --volumes 20 --gigabytes 7200 $tenant
  neutron quota-update --tenant_id $tenant --port 100 --floatingip 15
done
