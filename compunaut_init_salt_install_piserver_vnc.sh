#!/bin/bash
### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

# Install Netboot
  echo_red "INSTALL PISERVER AND VNC"

  echo_blue "Applying states"
  salt -C 'I@compunaut_vnc:* or I@compunaut_piserver:*' state.apply compunaut_vnc,compunaut_piserver --async
