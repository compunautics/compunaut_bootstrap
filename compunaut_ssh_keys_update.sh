#!/bin/bash
### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

### CREATE AND DEPLOY KEYS
  echo_red "CREATE AND DEPLOY KEYS"
  minion_wait

  echo_blue "Creating default users"
  salt '*' state.apply compunaut_default.users --state_output=mixed
  echo_blue "Creating keys"
  salt '*salt*' state.apply compunaut_hypervisor.ssh,compunaut_rundeck.keys --state_output=mixed
  echo_blue "Deploying private rundeck key"
  salt -C 'I@rundeck:*' state.apply compunaut_rundeck.private --state_output=mixed
  echo_blue "Deploying public keys"
  salt '*' state.apply compunaut_default.ssh,compunaut_rundeck.public --state_output=mixed
