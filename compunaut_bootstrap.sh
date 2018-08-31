#!/bin/bash
set -e
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

### FUNCTIONS
minion_wait() {
  echo -e "${BLUE}\nChecking minion readiness...${NC}"
  while [[ $(salt 'compunaut*' test.ping | grep -i "no response") ]]; do
    echo -e "${BLUE}Not all salt minions are ready...\nWaiting 5 seconds...${NC}"
    sleep 5
  done
}

echo_red() {
  local message=${1}
  echo -e "${RED}\n${message}${NC}"
}

echo_blue() {
  local message=${1}
  echo -e "${BLUE}\n${message}...${NC}"
}

### WARNING TO USERS
  echo_red "This script should be run as the root user of your intended ubuntu 16.04 hypervisor server."
  sleep 5

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
  salt-key -A -y

### SALT REPO SETUP
# Clone and Link Compunaut Salt Repos
  # Create base salt directories
  echo_blue "Creating salt directories"
  mkdir -pv /srv/{salt,salt-images,pillar}

  # Define compunaut formulas in array
  compunaut_repos="compunaut" 
  saltstack_formulas=( 
    keepalived-formula
    openvpn-formula
  )
        
  # Clone and link
  echo_blue "Cloning/fetching Compunaut repos from Github and setting up local directories"
  # Clone repos
  if [[ ! -d /srv/repos ]]; then
    git clone https://github.com/compunautics/${compunaut_repos}.git /srv/repos
    (cd /srv/repos && git submodule init)
  fi
  (cd /srv/repos && git submodule update --remote)
  # Link salt dirs
  for module in $(ls /srv/repos | grep compunaut); do
    if [[ -d /srv/repos/${module}/salt ]]; then
      if [[ ! -L /srv/salt/${module} ]]; then
        ln -s /srv/repos/${module}/salt /srv/salt/${module}
      fi
    fi
  # Link pillar dirs
    if [[ -d /srv/repos/${module}/pillar ]]; then
      if [[ ! -L /srv/pillar/${module} ]]; then
        ln -s /srv/repos/${module}/pillar /srv/pillar/${module}
      fi
    fi
  done

  # Clone and link other salt-formulas
  echo_blue "Cloning/fetching saltstack formulas"
  for formula in "${saltstack_formulas[@]}"; do
    # Clone repos
    sls_dir=$(cut -d- -f1 <<< ${formula})
    if [[ ! -d /srv/repos/${formula} ]]; then
      git clone https://github.com/saltstack-formulas/${formula}.git /srv/repos/${formula}
    fi
    # Link salt dirs
    if [[ ! -L /srv/salt/${sls_dir} ]]; then
      ln -s /srv/repos/${formula}/${sls_dir} /srv/salt/${sls_dir}
    fi
  done

  # Top is handled outside the loop
  if [[ ! -L /srv/salt/top.sls ]]; then
    ln -s /srv/repos/compunaut_top/salt_top.sls /srv/salt/top.sls
  fi
  if [[ ! -L /srv/pillar/top.sls ]]; then
    ln -s /srv/repos/compunaut_top/pillar_top.sls /srv/pillar/top.sls
  fi

### HYPERVISOR SETUP
# Highstate to set up the infrastructure and vms
  echo_blue "Refreshing pillars"
  salt '*' saltutil.refresh_pillar # refresh pillar before highstate

  echo_blue "Running salt to set up hypervisor"
  salt 'salt*' state.highstate # now run highstate

# Log into vms and configure salt
  echo_blue "Log into vms and configure hostname and salt"
  for ip in $(virsh net-dumpxml br1 | grep -oP "(?<=ip\=\').+?(?=\'\/>)"); do
    while [[ ! $(nc -vz ${ip} 22 2>&1 | grep -io "succeeded") ]]; do
      echo_blue "Not all minions are ready. Waiting 5 seconds"
      sleep 5
    done
    vm=$(virsh net-dumpxml br1 | grep ${ip} | grep -oP "(?<=name\=\').+?(?=\')")
    master_key=$(salt-key -f master.pub | grep -oP '(?<=master.pub:\s\s).+$')
    sshpass -p 'C0mpun4ut1cs!' ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -l compunaut ${ip} \
      "sudo hostnamectl set-hostname ${vm} && \
      sudo sed -ri 's/compunaut-minion/${vm}\n172.16.0.1\tsalt/g' /etc/hosts && \
      sudo sed -ri 's/#master_finger:.+$/master_finger: ${master_key}/g' /etc/salt/minion && \
      sudo systemctl start salt-minion && \
      sudo systemctl enable salt-minion"
  done

### MINION SETUP
# Accept all salt keys
  echo_blue "Accept salt keys from vms"
  sleep 10
  salt-key -A -y

# Configure mine on master and minions
  minion_wait
  echo_blue "Running compunaut_salt.master"
  salt 'salt*' state.apply compunaut_salt.master

  minion_wait
  echo_blue "Running compunaut_salt.minion"
  salt '*' state.apply compunaut_salt.minion

# Refresh pillars and mine before proceeding
  minion_wait
  echo_blue "Updating pillars"
  salt '*' saltutil.refresh_pillar
  sleep 15

  echo_blue "Updating mine"
  salt '*' mine.update
  sleep 15

# Create certs, then deploy openvpn
  minion_wait
  echo_blue "Generating openvpn certs for minions"
  salt 'salt*' state.apply compunaut_openvpn.certificates

  minion_wait
  echo_blue "Running highstate on vms"
  salt 'compunaut*' state.highstate
