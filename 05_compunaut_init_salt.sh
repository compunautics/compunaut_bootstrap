#!/bin/bash
### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

### HYPERVISOR SETUP
# Highstate to set up the infrastructure and vms
  echo_red "SET UP HYPERVISORS"
  update_data

  echo_blue "Install KVM and boot VMs"
  salt -C 'I@compunaut_hypervisor:*' state.apply compunaut_hypervisor --state_output=mixed

# Log into vms and configure salt
  minion_wait
  echo_blue "Logging into VMs and configuring hostname and salt"
  salt -C 'I@compunaut_hypervisor:*' state.apply compunaut_hypervisor.salt_vms --state_output=mixed

### MINION SETUP
# Accept all salt keys
  echo_red "SET UP COMPUNAUT MINIONS"
  echo_blue "Accepting salt keys from VMs"
  echo_green "Waiting 15 seconds"
  sleep 15

  salt-key -A -y
  echo_green "Waiting 30 seconds"
  sleep 30

# Configure mine on master and minions
  minion_wait
  echo_blue "Configure salt minions"
  salt '*' state.apply compunaut_salt.minion --async
  echo_green "Waiting 100 seconds"
  sleep 100

  minion_wait
  echo_blue "Sync all"
  salt '*'  saltutil.sync_all -b6 --batch-wait 20 1>/dev/null
  echo_green "Waiting 45 seconds"
  sleep 45

### DEPLOY COMPUNAUT
# Install keepalived
  echo_red "INSTALL KEEPALIVED"
  update_data

  echo_blue "Applying states"
  salt -C 'I@keepalived:vrrp_instance:*:virtual_router_id:*' state.apply compunaut_keepalived --async

# Install openvpn
  echo_red "DEPLOY OPENVPN"

  echo_blue "Generating OpenVPN certs for minions"
  salt '*salt*' state.apply compunaut_openvpn.ca,compunaut_openvpn.certificates --state_output=mixed

  minion_wait
  echo_blue "Deploying OpenVPN"
  salt -C 'I@openvpn:*' state.apply compunaut_openvpn,compunaut_default -b8 --batch-wait 15 --state_output=mixed

  echo_blue "Restarting OpenVPN"
  salt -C 'I@openvpn:*' cmd.run 'systemctl restart openvpn'

# Install dnsmasq
  echo_red "INSTALL CONSUL AND DNSMASQ"
  update_data

  echo_blue "Applying states"
  salt -C 'not I@compunaut_hypervisor:*' state.apply compunaut_consul,compunaut_dnsmasq -b8 --batch-wait 15 --state_output=mixed

# Install databases
  echo_red "INSTALL DATABASES"

  echo_blue "Installing MySQL, InfluxDB, and Influx Relay"
  salt -C 'I@mysql:server:*' state.apply compunaut_mysql,compunaut_influxdb --async

  echo_blue "Installing LDAP"
  salt -C 'I@openldap:slapd_services:*' state.apply compunaut_openvpn.deploy,compunaut_openldap --state_output=mixed
  echo_green "Waiting 120 seconds"
  sleep 120

  update_data

  echo_blue "Setting up Galera"
  salt -C 'I@mysql:server:*' state.apply compunaut_mysql.galera --async

  echo_blue "Setting up LDAP replication and memberOf module"
  salt -C 'I@openldap:slapd_services:*' state.apply compunaut_openldap.memberof,compunaut_openldap.repl --state_output=mixed

# Install Netboot
  echo_red "INSTALL NETBOOT"

  echo_blue "Applying states"
  salt -C 'I@compunaut_guacamole:* or I@compunaut_vnc:* or I@compunaut_piserver:*' state.apply compunaut_guacamole,compunaut_guacamole.mysql,compunaut_vnc,compunaut_piserver --async

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
  echo_green "Waiting 400 seconds"
  sleep 400

# FINAL SETUP
  echo_red "FINAL SETUP"
  update_data

  echo_blue "Highstating the Hypervisors one more time"
  salt -C 'I@compunaut_hypervisor:*' state.highstate --state_output=mixed

  minion_wait
  echo_blue "Highstating the VMs"
  salt -C 'not I@compunaut_hypervisor:*' state.highstate -b6 --batch-wait 15 --state_output=mixed

# Don't exit until all salt minions are answering
  echo_blue "All minions are now responding. You may run salt commands against them now"
