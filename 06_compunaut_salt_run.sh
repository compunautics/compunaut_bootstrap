#!/bin/bash

### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

  ./compunaut_init_salt_create_vms.sh
  minion_wait
  ./compunaut_init_salt_highstate.sh
  minion_wait
  ./compunaut_init_salt_install_dbs.sh
  minion_wait
  ./compunaut_init_salt_highstate.sh

### SOME POST RUN STUFF
  minion_wait
  salt '*netboot*' state.apply
  salt '*netboot*' cmd.run 'systemctl restart tomcat8'
