#!/bin/bash
### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

### SET UP KVM MINIONS
salt-call state.apply compunaut_kvm.install,compunaut_kvm.network,compunaut_salt
reboot
