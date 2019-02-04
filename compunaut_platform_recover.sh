#!/bin/bash

### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

  update_data

  echo_blue "Recover LDAP"
  salt -C 'I@openldap:slapd_services:*' state.apply compunaut_openvpn.deploy,compunaut_openldap --state_output=mixed

  echo_blue "Recover MySQL"
  salt -C 'I@mysql:server:*' state.apply compunaut_mysql.galera --state_output=mixed

  minion_wait

  ./compunaut_init_salt_highstate.sh
