#!/bin/bash

conf=/home/stack/postdeploy-automation/ceph-ansible/roles/ceph-common/templates/ceph.conf.j2
conf_short=$(basename $conf)

vars=(osd_journal_size osd_pool_default_pg_num osd_pool_default_pgp_num
osd_pool_default_size osd_pool_default_min_size auth_service_required
auth_cluster_required auth_client_required);

for var in ${vars[@]}; do
    sans_under=$(echo $var | sed 's/_/\ /g');
    if [[ $(grep "$sans_under" $conf) ]]
    then
        echo "Changing '$sans_under' to '$var' in $conf_short";
        sans_under_backslashed=$(echo $var | sed 's/_/\\\ /g');
        sed "s/$sans_under_backslashed/$var/g" -i $conf;
    fi
done
