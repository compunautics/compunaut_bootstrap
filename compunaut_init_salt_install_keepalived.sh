#!/bin/bash
### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

# Install keepalived
  echo_red "INSTALL KEEPALIVED"

  minion_wait
  echo_blue "Applying states"
  salt -C 'I@keepalived:vrrp_instance:*:virtual_router_id:*' state.apply compunaut_keepalived --async
