#!/bin/bash
### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

### SALT REPO SETUP
# Clone and Link Compunaut Salt Repos
  git clone https://github.com/compunautics/compunaut.git /srv
