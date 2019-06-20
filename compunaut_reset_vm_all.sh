#!/bin/bash
### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

# reset all vms on all hypervisors
time salt-run state.orch orch.reset_vms --state-output=mixed
