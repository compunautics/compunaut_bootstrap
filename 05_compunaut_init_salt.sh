#!/bin/bash
### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

### HYPERVISOR SETUP
# Highstate to set up the infrastructure and vms
  echo_red "SET UP HYPERVISORS"
  update_data

  minion_wait
  echo_blue "Highstating the kvm nodes"
  salt -C '*salt* or *kvm*' state.highstate --state_output=mixed

# Log into vms and configure salt
  minion_wait
  echo_blue "Logging into vms and configuring hostname and salt"
  salt -C '*salt* or *kvm*' state.apply compunaut_hypervisor.salt_vms --state_output=mixed

### MINION SETUP
# Accept all salt keys
  echo_red "SET UP COMPUNAUT MINIONS"
  echo_blue "Accepting salt keys from vms"
  sleep 30

  salt-key -A -y
  sleep 30

# Update all software on all minions
  minion_wait
  echo_blue "Updating all vms"
  salt -C 'not *salt* and not *kvm*' cmd.run 'apt-get update && apt-get install salt-minion -y' --async
  sleep 60

# Configure mine on master and minions
  minion_wait
  echo_blue "Running compunaut_salt"
  salt '*' state.apply compunaut_salt.minion --state_output=mixed

  minion_wait
  salt '*'  saltutil.sync_all
  sleep 60

### DEPLOY COMPUNAUT
  echo_red "DEPLOY OPENVPN"
  update_data
  sleep 60

  minion_wait
  echo_blue "Generating openvpn certs for minions"
  salt '*salt*' state.apply compunaut_openvpn.certificates --state_output=mixed

  minion_wait
  echo_blue "Installing openvpn"
  salt '*' state.apply compunaut_openvpn,compunaut_default --state_output=mixed

# Install databases
  echo_red "INSTALL DATABASES"
  update_data

  minion_wait
  echo_blue "Installing MySQL, InfluxDB, and Influx Relay"
  salt '*db*' state.apply compunaut_mysql,compunaut_influxdb --state_output=mixed --async

  echo_blue "Installing LDAP"
  salt '*ldap*' state.highstate --state_output=mixed --async

  update_data

  minion_wait
  echo_blue "Setting up Galera"
  salt '*db*' state.apply compunaut_mysql.galera --state_output=mixed

# Install consul
  echo_red "INSTALL CONSUL AND DNSMASQ"

  minion_wait
  echo_blue "Applying states"
  salt -C 'not *salt* and not *kvm*' state.apply compunaut_consul,compunaut_dnsmasq --state_output=mixed

# Install Grafana
  echo_red "INSTALL GRAFANA"

  minion_wait
  echo_blue "Applying states"
  salt '*monitor*' state.apply compunaut_grafana --async

# Install Rundeck
  echo_red "INSTALL RUNDECK"

  echo_blue "Applying states"
  salt '*rundeck*' state.apply compunaut_rundeck --async

# Install Gitlab
  echo_red "INSTALL GITLAB"

  echo_blue "Applying states"
  salt '*gitlab*' state.apply compunaut_gitlab --async
  minion_wait

# Running highstate
  echo_red "HIGHSTATE THE VMS"

  minion_wait
  echo_blue "Installing telegraf"
  salt '*' state.apply compunaut_telegraf --state_output=mixed

  echo_blue "Running highstate"
  salt -C 'not *salt* and not *kvm*' state.highstate --state_output=mixed

# Final kvm node setup
  echo_red "FINAL SETUP"
  update_data

  minion_wait
  echo_blue "Setting up dnsmasq, openvpn, openldap, and sssd on kvm nodes"
  salt -C '*salt* or *kvm*' state.apply compunaut_dnsmasq,compunaut_openvpn,compunaut_openldap,compunaut_sssd --state_output=mixed

  minion_wait
  echo_blue "Restart OpenVPN"
  salt -C '*salt* or *kvm*' cmd.run 'systemctl restart openvpn'

  update_data

  minion_wait
  echo_blue "Setting up consul on kvm nodes"
  salt -C '*salt* or *kvm*' state.apply compunaut_consul --state_output=mixed

# Don't exit until all salt minions are answering
  echo_blue "All minions are now responding. You may run salt commands against them now"
