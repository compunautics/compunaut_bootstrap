#!/bin/bash

vm_to_reset=${1}

for vm in ${vm_to_reset}; do
  virsh destroy ${vm}
  virsh undefine ${vm}
  salt-key -d ${vm} -y
  rm -fv /srv/salt-images/${vm}.qcow2
done
