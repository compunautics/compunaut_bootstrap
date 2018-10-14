#!/bin/bash
set -e
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

### FUNCTIONS
echo_red() {
  local message=${1}
  echo -e "${RED}\n${message}${NC}"
}

### WARNING TO USERS
  echo_red "This script should be run as the root user of your intended ubuntu 16.04 hypervisor server."
  sleep 2

# Set working directory as root dir for this script
  cd "${0%/*}"

# Set up salt master and minion
  ./compunaut_salt_master.sh

# Set up repositories
  ./compunaut_repo_setup.sh

# Run salt
  ./compunaut_salt_run.sh
