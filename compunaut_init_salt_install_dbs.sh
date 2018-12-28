#!/bin/bash
### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

# Install databases
  echo_red "INSTALL DATABASES"

  echo_blue "Installing MySQL, InfluxDB, and Influx Relay"
  salt -C 'I@mysql:server:*' state.apply compunaut_mysql,compunaut_influxdb --async

  echo_blue "Installing LDAP"
  salt -C 'I@openldap:slapd_services:*' state.apply compunaut_openvpn.deploy,compunaut_openldap,compunaut_openldap.repl,compunaut_openldap.memberof -b1 --state_output=mixed
  echo_green "Waiting 45 seconds"
  sleep 45

  update_data

  echo_blue "Setting up Galera"
  salt -C 'I@mysql:server:*' state.apply compunaut_mysql.galera --state_output=mixed
