#!/bin/bash

### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

### VARIABLES
vm_to_reset=${1}

# Recreate any lost VMs
update_data
echo_red "Recreate any lost VMs"
salt -C '*salt* or *kvm*' state.highstate

# Salt all VMs
minion_wait
echo_red "Salt all VMs"
salt -C '*salt* or *kvm*' state.apply compunaut_hypervisor.salt_vms

sleep 30
salt-key -A -y

# Update targeted VM
minion_wait
echo_red "Update targeted VM"
salt "${vm_to_reset}" cmd.run 'apt-get update && apt-get dist-upgrade -y'
sleep 90

# Configure mine on targeted VM
update_data
echo_red "Configure mine on targeted VM"
salt "${vm_to_reset}" state.apply compunaut_salt.minion
sleep 60
salt "${vm_to_reset}" saltutil.sync_all
sleep 60

# Deploy OpenVPN
update_data
echo_red "Deploy OpenVPN"
salt "${vm_to_reset}" state.apply compunaut_openvpn

# Highstate the VM
update_data
echo_red "Highstate the VM"
salt "${vm_to_reset}" state.highstate
