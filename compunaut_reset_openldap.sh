#!/bin/bash

### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

### SHUTDOWN AND PURGE SLAPD
minion_wait
salt -I 'compunaut_openldap:enabled:True' cmd.run 'systemctl stop slapd && apt-get purge slapd -y'

### REINSTALL OPENLDAP
salt -I 'compunaut_openldap:enabled:True' state.apply compunaut_openldap -b1 --state_output=mixed

