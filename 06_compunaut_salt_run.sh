#!/bin/bash

### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

  update_data
  ./compunaut_init_salt_create_vms.sh
  minion_wait
  ./compunaut_init_salt_highstate.sh
  minion_wait
  ./compunaut_init_salt_install_dbs.sh
  minion_wait
  ./compunaut_init_salt_highstate.sh
