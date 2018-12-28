#!/bin/bash
### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

# Install dnsmasq
  echo_red "INSTALL CONSUL AND DNSMASQ"

  echo_blue "Applying states"
  salt -C 'not I@compunaut_hypervisor:*' state.apply compunaut_consul,compunaut_dnsmasq -b8 --batch-wait 15 --state_output=mixed

  echo_blue "Restarting dnsmasq"
  salt '*' cmd.run 'systemctl restart dnsmasq'
