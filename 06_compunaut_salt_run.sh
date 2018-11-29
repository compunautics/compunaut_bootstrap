#!/bin/bash

### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

# Highstate the Hypervisors
update_data
echo_red "Highstate the Hypervisors"
salt -C '*salt* or *kvm*' state.highstate
sleep 20

# Salt all VMs
minion_wait
echo_red "Salt all VMs"
salt -C '*salt* or *kvm*' state.apply compunaut_hypervisor.salt_vms
sleep 20
salt-key -A -y

# Update all VMs
minion_wait
echo_red "Update VMs"
salt -C "not *salt* and not *kvm*" cmd.run 'apt-get update && apt-get dist-upgrade -y'
sleep 60

# Configure Mine on all Nodes
update_data
echo_red "Configure mine on all Nodes"
salt "*" state.apply compunaut_salt.minion
sleep 30
salt "*" saltutil.sync_all
sleep 30

# Highstate the VMs
update_data
echo_red "Highstate the VMs"
salt -C 'not *salt* and not *kvm*' state.highstate

# Highstate the VMs again
update_data
echo_red "Highstate the VMs again"
salt -C 'not *salt* and not *kvm*' state.highstate

# Recover LDAP
update_data
echo_red "Recover LDAP"
salt '*ldap*' state.apply compunaut_openldap,compunaut_openldap.memberof,compunaut_openldap.repl

# Bootstrap the MySQL Galera Cluster
update_data
echo_red "Bootstrap the MySQL Galera Cluster"
salt '*db*' state.apply compunaut_mysql.galera

# Highstate the VMs one last time
update_data
sleep 30
echo_red "Highstate the VMs one last time"
salt -C 'not *salt* and not *kvm*' state.highstate
