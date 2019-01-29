#!/bin/bash
### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

### HYPERVISOR SETUP
# Highstate to set up the infrastructure and vms
  update_data

  echo_red "SET UP HYPERVISORS"

  echo_blue "Install KVM and boot VMs"
  salt -C 'I@compunaut_hypervisor:*' state.apply compunaut_hypervisor,compunaut_default.udev --state_output=mixed

# Log into vms and configure salt
  echo_blue "Logging into VMs and configuring hostname and salt"
  salt -C 'I@compunaut_hypervisor:*' state.apply compunaut_hypervisor.salt_vms --state_output=mixed

### MINION SETUP
# Accept all salt keys
  echo_red "SET UP COMPUNAUT MINIONS"
  echo_blue "Accepting salt keys from VMs"
  echo_green "Waiting 15 seconds"
  sleep 15

  salt-key -A -y
  echo_green "Waiting 60 seconds"
  sleep 60

# Configure mine on master and minions
  minion_wait
  echo_blue "Configure salt minions"
  salt '*' state.apply compunaut_salt.minion -b4 --batch-wait 25 --state_output=mixed
  echo_green "Waiting 20 seconds"
  sleep 20

  minion_wait
  echo_blue "Sync all"
  salt '*'  saltutil.sync_all -b4 --batch-wait 25 1>/dev/null
