#!/bin/bash
### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

### Get positional vars
minion_hostname=${1}
salt_master=${2}

### INITIAL SALT SETUP
# Update sudoers so that sudo group members don't need a password
  echo_blue "Updating sudoers"
  sed -ri 's/^\%sudo\s+ALL=\(ALL:ALL\)+\sALL$/\%sudo\tALL=\(ALL:ALL\)\ NOPASSWD:ALL/g' /etc/sudoers

# Set up hostname
  echo_blue "Setting hostname if not set"
  hostnamectl set-hostname ${minion_hostname}
  if [[ ! `grep -P "127.0.1.1\s+${minion_hostname}" /etc/hosts` ]]; then  
    echo "127.0.1.1 ${minion_hostname}" | tee -a /etc/hosts
  fi

# Update Everything
  echo_blue "Performing updates"
  apt-get -qq update
  apt-get -q dist-upgrade -y

# Install Salt Minion
  echo_blue "Installing SaltStack if not installed"
  if [[ ! $(dpkg -l | egrep 'salt-minion') ]]; then
    if [[ ! $(apt-key list | grep "SaltStack Packaging Team") ]]; then
      wget -O - https://repo.saltstack.com/apt/ubuntu/16.04/amd64/latest/SALTSTACK-GPG-KEY.pub | sudo apt-key add -
    fi
    if [[ ! -f /etc/apt/sources.list.d/saltstack.list ]]; then
      echo "deb http://repo.saltstack.com/apt/ubuntu/16.04/amd64/latest xenial main" | tee -a /etc/apt/sources.list.d/saltstack.list
    fi
    apt-get update
    apt-get install salt-minion git -y
  fi

# Autoremove after installations
  echo_blue "Autoremoving no-longer-needed software"
  apt autoremove -y

# Configure Salt Minion to talk to master
  echo_blue "Configuring local salt minion to talk to salt master"
  if [[ ! $(grep "${salt_master}" /etc/hosts) ]]; then 
    sed -ri "s/^127.0.0.1\s+localhost$/127.0.0.1\tlocalhost\n${salt_master}\ salt/g" /etc/hosts
  fi
  systemctl restart salt-minion
