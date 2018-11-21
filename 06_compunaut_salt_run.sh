#!/bin/bash

# functions
update_data() {
  minion_wait
  echo_blue "Updating mine"
  salt '*' mine.update
  sleep 10

  minion_wait
  echo_blue "Updating pillar"
  salt '*' saltutil.refresh_pillar
  sleep 10
}

echo_red() {
  local message=${1}
  echo -e "${RED}\n${message}${NC}"
}

echo_blue() {
  local message=${1}
  echo -e "${BLUE}\n${message}...${NC}"
}

# ensure all vms running
echo_red "Highstate the Hypervisors"
salt -C '*salt* or *kvm*' state.highstate

# recover databases
echo_red "Rebootstrap the MySQL Galera Cluster"
salt '*db*' state.apply compunaut_mysql.galera

# highstate everything else
echo_red "Highstate the VMs"
salt '*compunaut*' state.highstate
