#!/bin/bash

# reset all vms on all hypervisors
salt -C 'salt* or kvm*' state.sls compunaut_hypervisor.reset

# delete all keys for all minions (except salt and kvm nodes)
salt-key -d 'compunaut*' -y

# delete all openvpn certs
rm -fv /srv/repos/compunaut_openvpn/salt/keys/*
