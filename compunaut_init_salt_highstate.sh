#!/bin/bash
### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

# Highstate all nodes
  echo_blue "Highstating the Hypervisors"
  salt -C 'I@compunaut_hypervisor:*' state.highstate --state_output=mixed

  echo_blue "Highstating the VMs"
  salt -C 'not I@compunaut_hypervisor:*' state.highstate --async
