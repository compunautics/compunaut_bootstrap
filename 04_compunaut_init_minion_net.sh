#!/bin/bash
### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

### SET UP KVM MINIONS
salt-call state.apply compunaut_hypervisor.ssh,compunaut_hypervisor.kvm,compunaut_hypervisor.network,compunaut_salt
reboot
