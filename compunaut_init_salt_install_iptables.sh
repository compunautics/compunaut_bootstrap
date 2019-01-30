#!/bin/bash
### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

### INSTALL IPTABLES
  echo_red "INSTALL IPTABLES"

  echo_blue "Applying states"
  salt '*' state.apply compunaut_iptables -b8 --batch-wait 10 --state_output=mixed
