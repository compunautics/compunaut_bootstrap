#!/bin/bash
### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

### INITIAL SALT MASTER SETUP
# Update sudoers so that sudo group members don't need a password
  echo_blue "Updating sudoers"
  sed -ri 's/^\%sudo\s+ALL=\(ALL:ALL\)+\sALL$/\%sudo\tALL=\(ALL:ALL\)\ NOPASSWD:ALL/g' /etc/sudoers

# Set up hostname
  echo_blue "Setting hostname if not set"
  hostnamectl set-hostname salt01
  if [[ ! `grep -P '127.0.1.1\s+salt01' /etc/hosts` ]]; then  
    echo "127.0.1.1 salt01" | tee -a /etc/hosts
  fi

# Update Everything
  echo_blue "Performing updates"
  apt-get -qq update
  apt-get -q dist-upgrade -y

# Install Salt Master and Minion
  echo_blue "Installing SaltStack if not installed"
  if [[ ! $(dpkg -l | egrep 'salt-master|salt-minion') ]]; then
    if [[ ! $(apt-key list | grep "SaltStack Packaging Team") ]]; then
      wget -O - https://repo.saltstack.com/apt/ubuntu/16.04/amd64/latest/SALTSTACK-GPG-KEY.pub | sudo apt-key add -
    fi
    if [[ ! -f /etc/apt/sources.list.d/saltstack.list ]]; then
      echo "deb http://repo.saltstack.com/apt/ubuntu/16.04/amd64/latest xenial main" | tee -a /etc/apt/sources.list.d/saltstack.list
    fi
    apt-get update
    apt-get install salt-master salt-minion git -y
  fi

# Autoremove after installations
  echo_blue "Autoremoving no-longer-needed software"
  apt autoremove -y

# Configure Salt Minion to talk to local master
  echo_blue "Configuring local salt minion to talk to salt master"
  sed -ri 's/^127.0.0.1\s+localhost$/127.0.0.1\tlocalhost\ salt/g' /etc/hosts
  systemctl restart salt-minion
  sleep 60
  salt-key -A -y
  sleep 60

# Set up KVM
  echo_blue "Setting up salt master hypervisor"
  salt 'salt*' state.apply compunaut_kvm.install --state_output=mixed
  sleep 60

  salt 'salt*' state.apply compunaut_kvm.network,compunaut_salt.master --state_output=mixed
