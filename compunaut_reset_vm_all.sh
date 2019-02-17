#!/bin/bash
### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

# reset all vms on all hypervisors
salt -C 'salt* or kvm*' state.sls compunaut_kvm.reset --state_output=mixed

# delete all keys for all minions (except salt and kvm nodes)
salt-key -d '*-vm*' -y
salt-key -d '*prtr*' -y

# delete all openvpn certs
rm -fv /srv/compunaut_pki/keys/*

# reset consul
minion_wait
salt '*' cmd.run 'systemctl stop consul'
salt '*' cmd.run 'rm -rfv /opt/consul/'

