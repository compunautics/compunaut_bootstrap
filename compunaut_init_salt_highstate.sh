#!/bin/bash
### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

# Highstate all nodes
  minion_wait
  echo_blue "Highstating the Hypervisors one more time"
  salt -C 'I@compunaut_hypervisor:*' state.highstate --state_output=mixed

  minion_wait
  echo_blue "Highstating the VMs"
  salt -C 'not I@compunaut_hypervisor:*' state.highstate -b6 --batch-wait 15 --state_output=mixed
