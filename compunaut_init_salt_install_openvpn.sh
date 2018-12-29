#!/bin/bash
### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

# Install openvpn
  echo_red "DEPLOY OPENVPN"

  echo_blue "Generating OpenVPN certs for minions"
  salt '*salt*' state.apply compunaut_openvpn.ca,compunaut_openvpn.certificates --state_output=mixed

  echo_blue "Deploying OpenVPN"
  salt -C 'I@openvpn:*' state.apply compunaut_openvpn,compunaut_default -b8 --batch-wait 15 --state_output=mixed

  echo_blue "Restarting OpenVPN"
  salt -C 'I@openvpn:*' cmd.run 'systemctl restart openvpn'
