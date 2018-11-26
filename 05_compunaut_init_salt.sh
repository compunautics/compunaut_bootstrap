#!/bin/bash
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

### FUNCTIONS
minion_wait() {
  echo -e "${BLUE}\nChecking minion readiness...${NC}"
  while [[ $(salt '*' test.ping | grep -i "no response") ]]; do
    echo -e "${BLUE}Not all salt minions are ready...\nWaiting 5 seconds...${NC}"
    sleep 5
  done
}

update_data() {
  minion_wait
  echo_blue "Updating mine"
  salt '*' mine.update
  sleep 30

  minion_wait
  echo_blue "Updating pillar"
  salt '*' saltutil.refresh_pillar -b8
  sleep 30
}

echo_red() {
  local message=${1}
  echo -e "${RED}\n${message}...${NC}"
}

echo_blue() {
  local message=${1}
  echo -e "${BLUE}\n${message}...${NC}"
}

### HYPERVISOR SETUP
# Highstate to set up the infrastructure and vms
  update_data

  echo_blue "SET UP HYPERVISOR"
  salt -C '*salt* or *kvm*' state.highstate # now run highstate

# Log into vms and configure salt
  echo_blue "Log into vms and configure hostname and salt"
  salt -C '*salt* or *kvm*' state.apply compunaut_hypervisor.salt_vms

### MINION SETUP
# Accept all salt keys
  echo_blue "SET UP COMPUNAUT MINIONS"
  echo_blue "Accept salt keys from vms"
  sleep 10
  salt-key -A -y

# Update all software on all minions
  minion_wait
  echo_blue "Updating all vms"
  salt -C 'not *salt* and not *kvm*' cmd.run 'apt-get update && apt-get dist-upgrade -y' -b8
  sleep 60

# Configure mine on master and minions
  minion_wait
  echo_blue "Running compunaut_salt"
  salt '*' state.apply compunaut_salt -b8
  sleep 60

### DEPLOY COMPUNAUT
  echo_blue "DEPLOY COMPUNAUT"
# Create certs, then deploy openvpn
  update_data
  sleep 60
  update_data
  sleep 60

  minion_wait
  echo_blue "Generating openvpn certs for minions"
  salt '*salt*' state.apply compunaut_openvpn.certificates

  minion_wait
  echo_blue "Installing openvpn on vpn servers"
  salt '*vpn*' state.apply compunaut_openvpn,compunaut_keepalived,compunaut_default

  minion_wait
  echo_blue "Installing openvpn on remaining vms"
  salt -C 'not *salt* and not *kvm*' state.apply compunaut_openvpn,compunaut_default

# Install databases
  update_data

  minion_wait
  echo_blue "Installing MySQL, InfluxDB, and Influx Relay"
  salt '*db*' state.apply compunaut_mysql,compunaut_influxdb

  update_data

  minion_wait
  echo_blue "Setting up Galera"
  salt '*db*' state.apply compunaut_mysql.galera

# Install openldap
  update_data

  minion_wait
  echo_blue "Installing OpenLDAP"
  salt '*ldap*' state.apply compunaut_openldap,compunaut_openldap.memberof,compunaut_openldap.repl

# Install consul
  update_data

  minion_wait
  echo_blue "Installing Consul and Dnsmasq"
  salt -C 'not *salt* and not *kvm*' state.apply compunaut_consul,compunaut_dnsmasq

# Install Grafana
  update_data

  minion_wait
  echo_blue "Installing Grafana"
  salt '*monitor*' state.apply compunaut_grafana -b1

# Install Gitlab
  minion_wait
  echo_blue "Installing Gitlab"
  salt '*gitlab*' state.apply compunaut_gitlab

# Running highstate
  update_data
  sleep 60

  minion_wait
  echo_blue "Running highstate on vms"
  salt -C 'not *salt* and not *kvm*' state.highstate

# Final kvm node setup
  update_data

  minion_wait
  echo_blue "Setting up dnsmasq, openvpn, and consul on kvm nodes"
  salt -C '*salt* or *kvm*' state.apply compunaut_dnsmasq,compunaut_openvpn,compunaut_openldap,compunaut_sssd
  salt -C '*salt* or *kvm*' cmd.run 'systemctl restart openvpn'

  update_data
  sleep 60
  update_data
  sleep 60

  salt -C '*salt* or *kvm*' state.apply compunaut_consul

# Don't exit until all salt minions are answering
  echo_blue "All minions are now responding. You may run salt commands against them now"
