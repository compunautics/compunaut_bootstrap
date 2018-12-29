#!/bin/bash
### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

### SPECIAL MINION_WAIT FUNCTION
minion_wait() {
  echo -e "${GREEN}\nChecking minion readiness...${NC}"
  while [[ $(salt -C 'I@mysql:server:* or I@openldap:slapd_services:*' test.ping | grep -iP "no response|not connected") ]]; do
    echo -e "${GREEN}Not all salt minions are ready...\nWaiting 5 seconds...${NC}"
    sleep 5
  done
  while [[ $(salt -C 'I@mysql:server:* or I@openldap:slapd_services:*' saltutil.running | grep -i "jid") ]]; do
    echo -e "${GREEN}Some minions are running jobs...\nWaiting 5 seconds...${NC}"
    sleep 5
  done
  echo -e "${GREEN}Minions ready. Waiting 10 seconds...${NC}"
  sleep 10
}

# Install databases
  echo_red "INSTALL DATABASES"

  echo_blue "Installing MySQL, InfluxDB, and Influx Relay"
  salt -C 'I@mysql:server:*' state.apply compunaut_mysql,compunaut_influxdb --async

  echo_blue "Installing LDAP"
  salt -C 'I@openldap:slapd_services:*' state.apply compunaut_openvpn.deploy,compunaut_openldap -b1 --state_output=mixed
  echo_green "Waiting 60 seconds"
  sleep 60

  update_data

  echo_blue "Setting up Galera"
  salt -C 'I@mysql:server:*' state.apply compunaut_mysql.galera --state_output=mixed
