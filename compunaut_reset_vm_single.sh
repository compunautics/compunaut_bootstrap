#!/bin/bash

vm_to_reset=${1}

salt -C '*salt* or *kvm*' cmd.run "virsh destroy ${vm_to_reset}"
salt -C '*salt* or *kvm*' cmd.run "virsh undefine ${vm_to_reset}"
salt -C '*salt* or *kvm*' cmd.run "salt-key -d ${vm_to_reset} -y"
salt -C '*salt* or *kvm*' cmd.run "rm -fv /srv/salt-images/${vm_to_reset}.qcow2"
