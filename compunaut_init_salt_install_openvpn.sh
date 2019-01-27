#!/bin/bash
### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

# Install openvpn
  echo_red "DEPLOY CONSUL AND OPENVPN"

  echo_blue "Generating OpenVPN certs for minions"
  salt '*salt*' state.apply compunaut_openvpn.ca,compunaut_openvpn.certificates --state_output=mixed

  minion_wait
  echo_blue "Deploying Consul and OpenVPN"
  salt -C 'I@openvpn:*' state.apply compunaut_consul,compunaut_openvpn,compunaut_default -b8 --batch-wait 25 --state_output=mixed

  echo_blue "Restarting OpenVPN"
  salt -C 'I@openvpn:*' cmd.run 'systemctl restart openvpn'
