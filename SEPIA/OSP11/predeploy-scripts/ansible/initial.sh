root_pass=calvin

for mgmt in refarch-r730xd-01.ipmi refarch-r730xd-02.ipmi refarch-r730xd-03.ipmi refarch-r730xd-04.ipmi refarch-r730xd-05.ipmi ; do ip=$(host $mgmt | awk '{ print $NF }'); /opt/dell/srvadmin/bin/idracadm7 -r $ip -u root -p $root_pass sshpkauth -f ~/.ssh/id_rsa.pub -i 2 -k 1; done

#old mount below
#172.21.1.118:/shares/nfs/iso/rhel73.iso
