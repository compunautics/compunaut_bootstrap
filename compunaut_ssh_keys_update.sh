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
  salt -I 'compunaut_salt:enabled:True' state.apply compunaut_pki.ssh --state_output=mixed
  echo_blue "Deploying keys"
  salt '*' state.apply compunaut_pki.deploy --state_output=mixed
