#!/bin/bash
set -e
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Set working directory as root dir for this script
cd "${0%/*}"

# Set up salt master and minion
./compunaut_salt_master.sh

# Set up repositories
./compunaut_repo_setup.sh

# Run salt
./compunaut_run_salt.sh
