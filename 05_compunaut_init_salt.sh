#!/bin/bash
### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

### HYPERVISOR SETUP
# Highstate to set up the infrastructure and vms
  echo_red "SET UP HYPERVISORS"
  update_data

  minion_wait
  salt -C '*salt* or *kvm*' state.highstate --state_output=mixed

# Log into vms and configure salt
  minion_wait
  echo_blue "Log into vms and configure hostname and salt"
  salt -C '*salt* or *kvm*' state.apply compunaut_hypervisor.salt_vms --state_output=mixed

### MINION SETUP
# Accept all salt keys
  echo_red "SET UP COMPUNAUT MINIONS"
  echo_blue "Accept salt keys from vms"
  sleep 30

  salt-key -A -y
  sleep 30

# Update all software on all minions
  minion_wait
  echo_blue "Updating all vms"
  salt -C 'not *salt* and not *kvm*' cmd.run 'apt-get update && apt-get dist-upgrade -y' --async
  sleep 210

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
  echo_blue "Installing openvpn on vpn servers"
  salt '*vpn*' state.apply compunaut_openvpn,compunaut_keepalived,compunaut_default --state_output=mixed

  minion_wait
  echo_blue "Installing openvpn on remaining vms"
  salt -C 'not *salt* and not *kvm*' state.apply compunaut_openvpn,compunaut_default --state_output=mixed

# Install databases
  echo_red "INSTALL DATABASES"
  update_data

  minion_wait
  echo_blue "Installing MySQL, InfluxDB, and Influx Relay"
  salt '*db*' state.apply compunaut_mysql,compunaut_influxdb --state_output=mixed

  update_data

  minion_wait
  echo_blue "Setting up Galera"
  salt '*db*' state.apply compunaut_mysql.galera --state_output=mixed

# Install openldap
  echo_red "INSTALL LDAP"
  update_data

  minion_wait
  echo_blue "Installing OpenLDAP"
  salt '*ldap*' state.apply compunaut_openldap,compunaut_openldap.memberof,compunaut_openldap.repl --state_output=mixed

# Install consul
  echo_red "INSTALL CONSUL AND DNSMASQ"
  update_data

  minion_wait
  salt -C 'not *salt* and not *kvm*' state.apply compunaut_consul,compunaut_dnsmasq --state_output=mixed

# Install Grafana
  echo_red "INSTALL GRAFANA"
  update_data

  minion_wait
  salt '*monitor*' state.apply compunaut_grafana --async

# Install Rundeck
  echo_red "INSTALL RUNDECK"

  minion_wait
  salt '*rundeck*' state.apply compunaut_rundeck --async

# Install Gitlab
  echo_red "INSTALL GITLAB"

  minion_wait
  salt '*gitlab*' state.apply compunaut_gitlab --async

# Running highstate
  echo_red "HIGHSTATE THE VMS"
  update_data
  sleep 60

  minion_wait
  echo_blue "Install telegraf"
  salt '*' state.apply compunaut_telegraf --state_output=terse

  echo_blue "Run highstate"
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
