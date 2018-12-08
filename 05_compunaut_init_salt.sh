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
  salt -C 'I@compunaut_hypervisor:*' state.highstate --state_output=mixed

# Log into vms and configure salt
  minion_wait
  echo_blue "Logging into VMs and configuring hostname and salt"
  salt -C 'I@compunaut_hypervisor:*' state.apply compunaut_hypervisor.salt_vms --state_output=mixed

### MINION SETUP
# Accept all salt keys
  echo_red "SET UP COMPUNAUT MINIONS"
  echo_blue "Accepting salt keys from VMss"
  sleep 30

  salt-key -A -y
  sleep 60

# Update salt-minions on vms
  minion_wait
  echo_blue "Update salt-minions on VMs"
  salt -C 'not I@compunaut_hypervisor:*' cmd.run 'apt-get update && apt-get install salt-minion -y' --async
  sleep 90

# Configure mine on master and minions
  minion_wait
  echo_blue "Configure salt minions"
  salt '*' state.apply compunaut_salt.minion --async
  sleep 120

  minion_wait
  echo_blue "Sync all"
  salt '*'  saltutil.sync_all -b6 --batch-wait 15 1>/dev/null
  sleep 90

### DEPLOY COMPUNAUT
# Install keepalived
  echo_red "INSTALL KEEPALIVED"
  update_data

  echo_blue "Applying states"
  salt -C 'I@keepalived:vrrp_instance:*:virtual_router_id:*' state.apply compunaut_keepalived --async

# Install openvpn
  update_data
  echo_red "DEPLOY OPENVPN"

  echo_blue "Generating OpenVPN certs for minions"
  salt '*salt*' state.apply compunaut_openvpn.certificates --state_output=mixed

  minion_wait
  echo_blue "Deploying OpenVPN"
  salt -C 'I@openvpn:*' state.apply compunaut_openvpn,compunaut_default -b8 --batch-wait 15 --state_output=mixed

  minion_wait
  echo_blue "Restarting OpenVPN"
  salt -C 'I@openvpn:*' cmd.run 'systemctl restart openvpn'

# Install dnsmasq
  echo_red "INSTALL DNSMASQ"
  update_data

  minion_wait
  echo_blue "Applying states"
  salt -C 'not I@compunaut_hypervisor:*' state.apply compunaut_dnsmasq -b8 --batch-wait 15 --state_output=mixed

# Install databases
  echo_red "INSTALL DATABASES"
  echo_blue "Installing MySQL, InfluxDB, and Influx Relay"
  salt -C 'I@mysql:server:*' state.apply compunaut_mysql,compunaut_influxdb --async

  echo_blue "Installing LDAP"
  salt -C 'I@openldap:slapd_services:*' state.apply compunaut_openvpn.deploy,compunaut_openldap --state_output=mixed
  sleep 120

  update_data

  echo_blue "Setting up Galera"
  salt 'I@mysql:server:*' state.apply compunaut_mysql.galera --async

  echo_blue "Setting up LDAP replication and memberOf module"
  salt 'I@openldap:slapd_services:*' state.apply compunaut_openldap.memberof,compunaut_openldap.repl --state_output=mixed

# Install consul
  echo_red "INSTALL CONSUL"
  update_data

  minion_wait
  echo_blue "Applying states"
  salt -C 'not I@compunaut_hypervisor:*' state.apply compunaut_consul -b8 --batch-wait 15 --state_output=mixed

# Install Gitlab
  echo_red "INSTALL GITLAB"

  minion_wait
  echo_blue "Applying states"
  salt -C 'I@gitlab:*' state.apply compunaut_gitlab --async

# Install Grafana
  echo_red "INSTALL GRAFANA"

  echo_blue "Applying states"
  salt -C 'I@grafana:*' state.apply compunaut_grafana --async

# Install Rundeck
  echo_red "INSTALL RUNDECK"

  echo_blue "Applying states"
  salt -C 'I@rundeck:*' state.apply compunaut_rundeck --async

# Install Haproxy
  echo_red "INSTALL HAPROXY"

  echo_blue "Applying states"
  salt -C 'I@haproxy:global:*' state.apply compunaut_haproxy --state_output=mixed

  sleep 360
  minion_wait

# FINAL SETUP
  update_data

  echo_red "FINAL SETUP"
  minion_wait
  echo_blue "Highstating the Hypervisors one more time"
  salt -C 'I@compunaut_hypervisor:*' state.highstate --state_output=mixed

  minion_wait
  echo_blue "Highstating the VMs"
  salt -C 'not I@compunaut_hypervisor:*' state.highstate -b6 --batch-wait 15 --state_output=mixed

# Don't exit until all salt minions are answering
  echo_blue "All minions are now responding. You may run salt commands against them now"
