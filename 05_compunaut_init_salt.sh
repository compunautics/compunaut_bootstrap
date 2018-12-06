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
  sleep 60

# Update all software on all minions
  minion_wait
  echo_blue "Updating all vms"
  salt -C 'not *salt* and not *kvm*' cmd.run 'apt-get update && apt-get install salt-minion -y' --async
  sleep 90

# Configure mine on master and minions
  minion_wait
  echo_blue "Running compunaut_salt"
  salt '*' state.apply compunaut_salt.minion --async
  sleep 120

  minion_wait
  echo_blue "Sync all"
  salt '*'  saltutil.sync_all -b6 --batch-wait 20 1>/dev/null
  sleep 90

### DEPLOY COMPUNAUT
# Install keepalived
  echo_red "INSTALL KEEPALIVED"
  update_data

  echo_blue "Applying states"
  salt -C '*vpn* or *proxy*' state.apply compunaut_keepalived --async

# Install openvpn
  echo_red "DEPLOY OPENVPN"

  echo_blue "Generating openvpn certs for minions"
  salt '*salt*' state.apply compunaut_openvpn.certificates --state_output=mixed

  minion_wait
  echo_blue "Deploying openvpn"
  salt -C 'not *salt* and not *kvm*' state.apply compunaut_openvpn,compunaut_default -b6 --batch-wait 20 --state_output=mixed

# Install dnsmasq
  echo_red "INSTALL DNSMASQ"
  update_data

  minion_wait
  echo_blue "Applying states"
  salt -C 'not *salt* and not *kvm*' state.apply compunaut_dnsmasq -b6 --batch-wait 20 --state_output=mixed

# Install databases
  echo_red "INSTALL DATABASES"
  echo_blue "Installing MySQL, InfluxDB, and Influx Relay"
  salt '*db*' state.apply compunaut_mysql,compunaut_influxdb --async

  echo_blue "Installing LDAP"
  salt '*ldap*' state.highstate --state_output=mixed

  update_data

  echo_blue "Setting up Galera"
  salt '*db*' state.apply compunaut_mysql.galera --async

  echo_blue "Setting up ldap replication and memberof module"
  salt '*ldap*' state.apply compunaut_openldap.memberof,compunaut_openldap.repl --state_output=mixed

# Install consul
  echo_red "INSTALL CONSUL"
  update_data

  minion_wait
  echo_blue "Applying states"
  salt -C 'not *salt* and not *kvm*' state.apply compunaut_consul -b6 --batch-wait 20 --state_output=mixed

# Install Gitlab
  echo_red "INSTALL GITLAB"

  minion_wait
  echo_blue "Applying states"
  salt '*gitlab*' state.apply compunaut_gitlab --async

# Install Grafana
  echo_red "INSTALL GRAFANA"

  echo_blue "Applying states"
  salt '*monitor*' state.apply compunaut_grafana --async

# Install Rundeck
  echo_red "INSTALL RUNDECK"

  echo_blue "Applying states"
  salt '*rundeck*' state.apply compunaut_rundeck --async

# Install Haproxy
  echo_red "INSTALL HAPROXY"

  echo_blue "Applying states"
  salt '*proxy*' state.apply compunaut_haproxy --state_output=mixed

  sleep 360
  minion_wait

# Running highstate
  echo_red "HIGHSTATE THE VMS"

  minion_wait
  echo_blue "Running highstate"
  salt -C 'not *salt* and not *kvm*' state.highstate -b6 --batch-wait 20 --state_output=mixed

# Final kvm node setup
  echo_red "FINAL SETUP"
  update_data

  minion_wait
  echo_blue "Highstating the Hypervisors one more time"
  salt -C '*salt* or *kvm*' state.apply compunaut_openvpn,compunaut_consul,compunaut_dnsmasq,compunaut_telegraf,compunaut_sssd,compunaut_openldap,compunaut_default,compunaut_iptables --state_output=mixed

  echo_blue "Restarting openvpn"
  salt '*' cmd.run 'systemctl restart openvpn'

# Don't exit until all salt minions are answering
  echo_blue "All minions are now responding. You may run salt commands against them now"
