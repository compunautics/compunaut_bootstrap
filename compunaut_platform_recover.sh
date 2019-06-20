#!/bin/bash

### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

  echo_blue "Update Data"
  time salt-run state.orch orch.update_data --state-output=mixed --log-level=quiet # update data

  echo_blue "Restart dnsmasq"
  time salt '*' cmd.run 'systemctl restart dnsmasq'

  echo_blue "Restart Chrony"
  time salt '*' cmd.run 'systemctl restart chrony'

  echo_blue "Recover LDAP"
  time salt -C 'I@compunaut_openldap:enabled:True' state.apply compunaut_openldap --state_output=mixed --log-level=quiet

  echo_blue "Recover MySQL"
  time salt -C 'I@compunaut_mysql:enabled:True' state.apply compunaut_mysql.galera --state_output=mixed --log-level=quiet

  minion_wait

  time salt-run state.orch orch.highstate --state-output=mixed --log-level=quiet

