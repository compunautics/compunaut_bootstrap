#!/bin/bash

### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

### SHUT DOWN CONSUL AND DELETE DATA
minion_wait
salt '*' cmd.run 'systemctl stop consul'
salt '*' cmd.run 'rm -rfv /opt/consul/'

### REINSTALL CONSUL
update_data

minion_wait
salt '*' state.apply compunaut_consul
