#!/bin/bash

### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

# ensure all vms running
update_data
echo_red "Highstate the Hypervisors"
salt -C '*salt* or *kvm*' state.highstate

# recover databases
minion_wait
echo_red "Bootstrap the MySQL Galera Cluster"
salt '*db*' state.apply compunaut_mysql.galera

# highstate everything else
echo_red "Highstate the VMs"
salt -C 'not *salt* and not *kvm*' state.highstate

update_data
sleep 60

echo_red "Highstate the VMs again"
salt -C 'not *salt* and not *kvm*' state.highstate

echo_red "Recover LDAP"
salt '*ldap*' state.apply compunaut_openldap,compunaut_openldap.memberof,compunaut_openldap.repl
