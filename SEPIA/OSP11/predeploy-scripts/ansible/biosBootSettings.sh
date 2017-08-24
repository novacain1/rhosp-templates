for n in 6 7 8 9 11 ; do
  ip=172.21.32.${n}
  echo "IP: $ip"
  racadm -r $ip -u root -p calvin set BIOS.biosbootsettings.BootSeq NIC.Integrated.1-1-1,HardDisk.List.1-1
  racadm -r $ip -u root -p calvin jobqueue create BIOS.Setup.1-1 -r pwrcycle -s TIME_NOW -e TIME_NA
done
