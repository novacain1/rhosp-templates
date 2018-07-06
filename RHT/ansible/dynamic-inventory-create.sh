#!/bin/bash
pushd /home/stack
# Create a directory for ansible
mkdir -p ansible/inventory
pushd ansible
# create ansible.cfg
cat << EOF > ansible.cfg
[defaults]
inventory = inventory
library = /usr/share/openstack-tripleo-validations/validations/library
EOF
# Create a dynamic inventory script
cat << EOF > inventory/hosts
#!/bin/bash
# Unset some things in case someone has a V3 environment loaded
unset OS_IDENTITY_API_VERSION
unset OS_PROJECT_ID
unset OS_PROJECT_NAME
unset OS_USER_DOMAIN_NAME
unset OS_IDENTITY_API_VERSION
source ~/stackrc
DEFPLAN=overcloud
PLAN_NAME=\$(openstack stack list -f csv -c 'Stack Name' | tail -n 1 | sed -e 's/"//g')
export TRIPLEO_PLAN_NAME=\${PLAN_NAME:-\$DEFPLAN}
/usr/bin/tripleo-ansible-inventory \$*
EOF
chmod 755 inventory/hosts
# run inventory/hosts.sh --list for example output
cat << EOF >> ~/.ssh/config
Host *
 StrictHostKeyChecking no
EOF
chmod 600 ~/.ssh/config
