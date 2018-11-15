#!/bin/bash

salt-call state.apply compunaut_hypervisor.ssh,compunaut_hypervisor.kvm,compunaut_hypervisor.network,compunaut_salt
reboot
