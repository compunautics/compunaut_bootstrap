#!/bin/bash

### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

### SHUTDOWN AND PURGE SLAPD
minion_wait
salt '*ldap*' cmd.run 'systemctl stop slapd && apt-get purge slapd -y'

### REINSTALL OPENLDAP
salt '*ldap*' state.apply compunaut_openldap,compunaut_openldap.memberof,compunaut_openldap.repl -b1 --state_output=mixed

