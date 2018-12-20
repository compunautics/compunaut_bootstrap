#!/bin/bash
### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

# Install Netboot
  echo_red "INSTALL NETBOOT"

  minion_wait
  echo_blue "Applying states"
  salt -C 'I@compunaut_guacamole:* or I@compunaut_vnc:* or I@compunaut_piserver:*' state.apply compunaut_guacamole,compunaut_guacamole.mysql,compunaut_vnc,compunaut_piserver --async

# Install Gitlab
  echo_red "INSTALL GITLAB"

  echo_blue "Applying states"
  salt -C 'I@gitlab:*' state.apply compunaut_gitlab --async

# Install Grafana
  echo_red "INSTALL GRAFANA"

  echo_blue "Applying states"
  salt -C 'I@grafana:*' state.apply compunaut_grafana --async

# Install Rundeck
  echo_red "INSTALL RUNDECK"

  echo_blue "Applying states"
  salt -C 'I@rundeck:*' state.apply compunaut_rundeck --async

# Install Haproxy
  echo_red "INSTALL HAPROXY"

  echo_blue "Applying states"
  salt -C 'I@haproxy:global:*' state.apply compunaut_haproxy --state_output=mixed
