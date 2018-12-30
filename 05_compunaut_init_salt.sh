#!/bin/bash
### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

### HYPERVISOR SETUP
  time ./compunaut_init_salt_create_vms.sh

  echo_green "Waiting 45 seconds"
  sleep 45

### DEPLOY COMPUNAUT
  update_data
  time ./compunaut_init_salt_install_iptables.sh
  minion_wait
  time ./compunaut_init_salt_install_keepalived.sh
  time ./compunaut_init_salt_install_openvpn.sh
  update_data
  time ./compunaut_init_salt_install_dns.sh
  time ./compunaut_init_salt_install_piserver_vnc.sh
  time ./compunaut_init_salt_install_dbs.sh
  minion_wait
  time ./compunaut_init_salt_install_apps.sh

  echo_green "Waiting 300 seconds"
  sleep 300

# FINAL SETUP
  update_data

  echo_red "FINAL SETUP"
  time ./compunaut_init_salt_highstate.sh
  time ./compunaut_ssh_keys_update.sh

# Don't exit until all salt minions are answering
  minion_wait
  echo_blue "All minions are now responding. You may run salt commands against them now"
