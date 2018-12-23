#!/bin/bash
### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

### HYPERVISOR SETUP
  ./compunaut_init_salt_create_vms.sh

  echo_green "Waiting 45 seconds"
  sleep 45

### DEPLOY COMPUNAUT
  update_data
  ./compunaut_init_salt_install_keepalived.sh
  ./compunaut_init_salt_install_openvpn.sh
  update_data
  ./compunaut_init_salt_install_dns.sh
  ./compunaut_init_salt_install_dbs.sh
  ./compunaut_init_salt_install_apps.sh

  echo_green "Waiting 600 seconds"
  sleep 600

# FINAL SETUP
  echo_red "FINAL SETUP"

  update_data
  ./compunaut_init_salt_highstate.sh
  ./compunaut_ssh_keys_update.sh

# Don't exit until all salt minions are answering
  minion_wait
  echo_blue "All minions are now responding. You may run salt commands against them now"
