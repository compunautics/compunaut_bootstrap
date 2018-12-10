#!/bin/bash

### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

# Highstate the Hypervisors
minion_wait
echo_red "Highstate the Hypervisors"
salt -C 'I@compunaut_hypervisor:*' state.highstate --state_output=mixed

# Salt all VMs
minion_wait
echo_red "Salt all VMs"
salt -C 'I@compunaut_hypervisor:*' state.apply compunaut_hypervisor.salt_vms --state_output=mixed
sleep 20

salt-key -A -y
sleep 20

# Update all VMs
minion_wait
echo_red "Update all VMs"
salt -C "not I@compunaut_hypervisor:*" cmd.run 'apt-get update && apt-get dist-upgrade -y' --async
sleep 180

# Configure Mine on all Nodes
minion_wait
echo_red "Configure mine on all Nodes"
salt "*" state.apply compunaut_salt.minion --async
sleep 30

salt "*" saltutil.sync_all 1>/dev/null
sleep 30

# Highstate the VMs
update_data

echo_red "Highstate the VMs"
salt -C 'not I@compunaut_hypervisor:*' state.highstate -b8 --batch-wait 15 --state_output=mixed

# Recover LDAP
update_data

echo_red "Recover LDAP"
salt -C 'I@openldap:slapd_services:*' state.apply compunaut_openldap,compunaut_openldap.memberof,compunaut_openldap.repl --async

# Bootstrap the MySQL Galera Cluster
echo_red "Bootstrap the MySQL Galera Cluster"
salt -C 'I@mysql:server:*' state.apply compunaut_mysql.galera --async

# Highstate the VMs one last time
update_data
echo_red "Highstate the VMs one last time"
salt -C 'not I@compunaut_hypervisor:*' state.highstate -b8 --batch-wait 15 --state_output=mixed

# Apply Consul states to hypervisors
echo_red "Apply consul states to hypervisors"
salt -C 'I@compunaut_hypervisor:*' state.apply compunaut_consul
