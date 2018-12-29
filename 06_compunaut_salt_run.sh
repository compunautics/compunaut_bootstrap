#!/bin/bash

### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

  ./compunaut_init_salt_create_vms.sh
  ./compunaut_init_salt_highstate.sh
  ./compunaut_init_salt_install_dbs.sh
  ./compunaut_init_salt_highstate.sh
