#!/bin/bash

# ensure all vms running
salt -C '*salt* or *kvm*' state.apply compunaut_hypervisor.vms,compunaut_consul

# recover databases
salt '*db*' state.apply compunaut_mysql.galera,compunaut_influxdb

# highstate everything else
salt '*compunaut*' state.highstate
