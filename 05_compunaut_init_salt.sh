#!/bin/bash
### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

### UPDATE REMOTES
  echo_red "UPDATE REMOTES"
  salt-run cache.clear_git_lock gitfs type=update
  salt-run fileserver.update backend=gitfs

### HYPERVISOR SETUP
  echo_red "SET UP HYPERVISORS"
  time salt-run state.orch orch.update_data --state-output=mixed --log-level=quiet # update data
  echo_blue "Install KVM, boot, and salt VMs"
  time salt-run state.orch orch.create_and_salt_vms --state-output=mixed --log-level=quiet

  echo_green "Waiting 60 seconds"
  sleep 60

  time salt-run state.orch orch.configure_minions --state-output=mixed --log-level=quiet
  time salt-run state.orch orch.update_data --state-output=mixed --log-level=quiet # update data

### DEPLOY COMPUNAUT
  minion_wait

  echo_red "SET UP DEFAULT ENVIRONMENT"
  time salt-run state.orch orch.update_data --state-output=mixed --log-level=quiet # update data
  echo_blue "Generate and deploy PKI"
  time salt-run state.orch orch.generate_pki --state-output=mixed --log-level=quiet
  echo_blue "Install default environment, and apply iptables rules"
  time salt-run state.orch orch.apply_default_env --state-output=mixed --log-level=quiet

  minion_wait

  echo_red "DEPLOY COMPUNAUT"
  echo_blue "Install Keepalived, DNS, and Consul"
  time salt-run state.orch orch.install_keepalived_dns_consul --state-output=mixed --log-level=quiet
  time salt-run state.orch orch.update_data --state-output=mixed --log-level=quiet # update data

  echo_blue "Install Piserver"
  salt-run state.orch orch.install_piserver --async
  echo_blue "Install OpenLDAP"
  salt-run state.orch orch.install_openldap --async
  echo_blue "Install NFS"
  salt-run state.orch orch.install_nfs --async

  echo_blue "Install MySQL"
  time salt-run state.orch orch.install_mysql --state-output=mixed --log-level=quiet
  echo_blue "Install InfluxDB"
  salt-run state.orch orch.install_influxdb --async

  echo_green "Waiting 180 seconds"
  sleep 180
  minion_wait

  echo_blue "Install Compunaut Applications"
  echo_green "Install Dashboard"
  salt-run state.orch orch.install_dashboard --async
  echo_green "Install Grafana"
  salt-run state.orch orch.install_grafana --async
  echo_green "Install Rundeck"
  salt-run state.orch orch.install_rundeck --async
  echo_green "Install Gitlab"
  salt-run state.orch orch.install_gitlab --async
  echo_green "Install Guacamole"
  time salt-run state.orch orch.install_guacamole --state-output=mixed --log-level=quiet

# FINAL SETUP
  echo_green "Waiting 180 seconds"
  sleep 180
  minion_wait

  echo_red "FINAL SETUP"
  time salt-run state.orch orch.update_data --state-output=mixed --log-level=quiet # update data
  time salt-run state.orch orch.highstate --state-output=mixed --log-level=quiet

# Don't exit until all salt minions are answering
  minion_wait
  echo_blue "All minions are now responding. You may run salt commands against them now"
