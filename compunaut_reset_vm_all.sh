#!/bin/bash

# reset all vms on all hypervisors
salt -C 'salt* or kvm*' state.sls compunaut_hypervisor.reset --state_output=mixed

# delete all keys for all minions (except salt and kvm nodes)
salt-key -d '*vm*' -y
salt-key -d '*prtr*' -y

# delete all openvpn certs
rm -fv /srv/repos/compunaut_openvpn/salt/keys/*
