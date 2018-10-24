#!/bin/bash
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

### FUNCTIONS
minion_wait() {
  echo -e "${BLUE}\nChecking minion readiness...${NC}"
  while [[ $(salt 'compunaut*' test.ping | grep -i "no response") ]]; do
    echo -e "${BLUE}Not all salt minions are ready...\nWaiting 5 seconds...${NC}"
    sleep 5
  done
}

echo_red() {
  local message=${1}
  echo -e "${RED}\n${message}${NC}"
}

echo_blue() {
  local message=${1}
  echo -e "${BLUE}\n${message}...${NC}"
}

### HYPERVISOR SETUP
# Highstate to set up the infrastructure and vms
  echo_blue "Refreshing pillars"
  salt '*' saltutil.refresh_pillar # refresh pillar before highstate

  echo_blue "Running salt to set up hypervisor"
  salt -C 'salt* or kvm*' state.highstate # now run highstate

# Log into vms and configure salt
  echo_blue "Log into vms and configure hostname and salt"
  salt -C 'salt* or kvm*' state.apply compunaut_hypervisor.salt_vms

### MINION SETUP
# Accept all salt keys
  echo_blue "Accept salt keys from vms"
  sleep 10
  salt-key -A -y

# Configure mine on master and minions
  minion_wait
  echo_blue "Running compunaut_salt"
  salt 'salt*' state.apply compunaut_salt.master
  sleep 15

  minion_wait
  salt '*' state.apply compunaut_salt

# Refresh pillars and mine before proceeding
  sleep 15
  minion_wait
  echo_blue "Updating pillars"
  salt '*' saltutil.refresh_pillar
  sleep 45

  echo_blue "Updating mine"
  salt '*' mine.update
  sleep 15

# Create certs, then deploy openvpn
  minion_wait
  echo_blue "Generating openvpn certs for minions"
  salt 'salt*' state.apply compunaut_openvpn.certificates

  minion_wait
  echo_blue "Installing openvpn on vpn servers"
  salt 'compunaut-vpn*' state.apply compunaut_openvpn,compunaut_keepalived,compunaut_default

  minion_wait
  echo_blue "Installing openvpn on remaining vms"
  salt 'compunaut*' state.apply compunaut_openvpn,compunaut_default

# Install databases
  minion_wait
  echo_blue "Updating mine"
  salt '*' mine.update
  sleep 15

  minion_wait
  echo_blue "Updating pillar"
  salt '*' saltutil.refresh_pillar
  sleep 15

  echo_blue "Installing MySQL, InfluxDB, and Influx Relay"
  salt 'compunaut-db*' state.apply compunaut_mysql,compunaut_influxdb

  echo_blue "Updating mine"
  salt '*' mine.update
  sleep 15 

  echo_blue "Setting up Galera"
  salt 'compunaut-db*' state.apply compunaut_mysql.galera

# Install consul
  minion_wait
  echo_blue "Updating mine"
  salt '*' mine.update
  sleep 15

  minion_wait
  echo_blue "Updating pillar"
  salt '*' saltutil.refresh_pillar
  sleep 15

  minion_wait
  echo_blue "Installing Consul"
  salt 'compunaut*' state.apply compunaut_consul

# Running highstate
  minion_wait
  echo_blue "Updating mine"
  salt '*' mine.update
  sleep 15

  minion_wait
  echo_blue "Updating pillar"
  salt '*' saltutil.refresh_pillar
  sleep 15

  minion_wait
  echo_blue "Running highstate on vms"
  salt 'compunaut*' state.highstate

# Run dns on salt again
  echo_blue "Setting up dnsmasq on salt master"
  salt 'salt*' state.apply compunaut_dnsmasq

# Don't exit until all salt minions are answering
  echo_blue "All done! Waiting for all minions to respond to test pings, but you can ctrl-c out of the script now"
  minion_wait
  echo_blue "All minions are now responding. You may run salt commands against them now"
