#!/bin/bash
### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

# Install Gitlab
  echo_red "INSTALL GITLAB"

  echo_blue "Applying states"
  salt -C 'I@gitlab:*' state.apply compunaut_gitlab --async

# Install Netboot
  echo_red "INSTALL GUACAMOLE"

  echo_blue "Applying states"
  salt -C 'I@compunaut_guacamole:*' state.apply compunaut_guacamole.mysql,compunaut_guacamole --async

# Install Rundeck
  echo_red "INSTALL RUNDECK"

  echo_blue "Applying states"
  salt -C 'I@rundeck:*' state.apply compunaut_rundeck --async

# Install Haproxy
  echo_red "INSTALL HAPROXY"

  echo_blue "Applying states"
  salt -C 'I@haproxy:global:*' state.apply compunaut_haproxy --async

# Install Grafana
  echo_green "Wait 30 seconds"
  sleep 30

  echo_red "INSTALL GRAFANA"

  echo_blue "Applying states"
  salt -C 'I@grafana:*' state.apply compunaut_grafana --state_output=mixed -b1
