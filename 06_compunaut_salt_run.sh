#!/bin/bash

# functions
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

minion_wait() {
  echo -e "${BLUE}\nChecking minion readiness...${NC}"
  while [[ $(salt '*' test.ping | grep -i "no response") ]]; do
    echo -e "${BLUE}Not all salt minions are ready...\nWaiting 5 seconds...${NC}"
    sleep 5
  done
}

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
  echo -e "${RED}\n${message}...${NC}"
}

echo_blue() {
  local message=${1}
  echo -e "${BLUE}\n${message}...${NC}"
}

# ensure all vms running
update_data
echo_red "Highstate the Hypervisors"
salt -C '*salt* or *kvm*' state.highstate

# recover databases
minion_wait
echo_red "Rebootstrap the MySQL Galera Cluster"
salt '*db*' state.apply compunaut_mysql.galera

# highstate everything else
echo_red "Highstate the VMs"
salt -C 'not *salt* and not *kvm*' state.highstate

update_data
sleep 20
update_data
sleep 20

salt -C 'not *salt* and not *kvm*' state.highstate
