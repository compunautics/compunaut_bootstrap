#!/bin/bash
### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

# Install keepalived
  echo_red "INSTALL KEEPALIVED"

  echo_blue "Applying states"
  salt -C 'I@keepalived:vrrp_instance:*:virtual_router_id:*' state.apply compunaut_keepalived --async

  echo_blue "Waiting 45 seconds"
  sleep 45

