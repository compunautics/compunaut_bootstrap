#!/bin/bash
set -e
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Echo warning to users
  echo -e "#####${RED}\nThis script should be run as the root user of your intended ubuntu 16.04 hypervisor server.\n#####${NC}"
  sleep 5

# Update sudoers so that sudo group members don't need a password
  echo -e "${BLUE}\nUpdating sudoers...${NC}"
  sed -ri 's/^\%sudo\s+ALL=\(ALL:ALL\)+\sALL$/\%sudo\tALL=\(ALL:ALL\)\ NOPASSWD:ALL/g' /etc/sudoers

# Set up hostname
  echo -e "${BLUE}\nSetting hostname if not set...${NC}"
  hostnamectl set-hostname salt01
  if [[ ! `grep -P '127.0.1.1\s+salt01' /etc/hosts` ]]; then  
    echo "127.0.1.1 salt01" | tee -a /etc/hosts
  fi

# Update Everything
  echo -e "${BLUE}\nPerforming updates...${NC}"
  apt-get -qq update
  apt-get -q dist-upgrade -y

# Install Salt Master and Minion
  echo -e "${BLUE}\nInstalling SaltStack if not installed...${NC}"
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
  echo -e "${BLUE}\nAutoremoving no-longer-needed software...${NC}"
  apt autoremove -y

# Configure Salt Minion to talk to local master
  echo -e "${BLUE}\nConfiguring local salt minion to talk to salt master...${NC}"
  sed -ri 's/^127.0.0.1\s+localhost$/127.0.0.1\tlocalhost\ salt/g' /etc/hosts
  salt-key -A -y

# Clone and Link Compunaut Salt Repos
  # Create base salt directories
  echo -e "${BLUE}\nCreating salt directories...${NC}"
  mkdir -pv /srv/{salt,salt-images,pillar,repos}

  # Define compunaut formulas in array
  compunaut_repos=( compunaut_default compunaut_hypervisor compunaut_top )
        
  # Clone and link
  echo -e "${BLUE}\nCloning/fetching Compunaut repos from Github and setting up local directories...${NC}"
  for repo in "${compunaut_repos[@]}"; do
    # Clone repos
    if [[ ! -d /srv/repos/${repo} ]]; then
      git clone https://github.com/compunautics/${repo}.git /srv/repos/${repo}
    fi
    (cd /srv/repos/${repo} && git pull)
    # Link salt dirs
    if [[ -d /srv/repos/${repo}/salt ]]; then
      if [[ ! -L /srv/salt/${repo} ]]; then
        ln -s /srv/repos/${repo}/salt /srv/salt/${repo}
      fi
    fi
    # Link pillar dirs
    if [[ -d /srv/repos/${repo}/pillar ]]; then
      if [[ ! -L /srv/pillar/${repo} ]]; then
        ln -s /srv/repos/${repo}/pillar /srv/pillar/${repo}
      fi
    fi
  done

  # Top is handled outside the loop
  if [[ ! -L /srv/salt/top.sls ]]; then
    ln -s /srv/repos/compunaut_top/salt_top.sls /srv/salt/top.sls
  fi
  if [[ ! -L /srv/pillar/top.sls ]]; then
    ln -s /srv/repos/compunaut_top/pillar_top.sls /srv/pillar/top.sls
  fi

# Highstate to set up the infrastructure and vms
  echo -e "${BLUE}\nRefreshing pillars and running highstate...${NC}"
  salt '*' saltutil.refresh_pillar # refresh pillar before highstate
  sleep 15 # wait a bit
  salt 'salt*' state.highstate # now run highstate

# Wait a bit for the vms to finish booting
  if [[ ! $(virsh list | grep -i compunaut) ]]; then
    echo -e "${BLUE}\nWait 30 seconds for vms to boot...${NC}"
    sleep 30
  fi

# Log into vms and configure salt
  echo -e "${BLUE}\nLog into vms and configure hostname and salt...${NC}"
  for ip in $(virsh net-dumpxml br1 | grep -oP "(?<=ip\=\').+?(?=\'\/>)"); do
    vm=$(virsh net-dumpxml br1 | grep ${ip} | grep -oP "(?<=name\=\').+?(?=\')")
    master_key=$(salt-key -f master.pub | grep -oP '(?<=master.pub:\s\s).+$')
    sshpass -p 'C0mpun4ut1cs!' ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -l compunaut ${ip} \
      'sudo hostnamectl set-hostname ${vm} && \
      sudo sed -ri "s/compunaut-minion/${vm}\n172.16.0.1\tsalt/g" /etc/hosts && \
      sudo sed -ri "s/#master_finger: \\'\\'/master_finger: ${master_key}/g" /etc/salt/minion && \
      sudo systemctl start salt-minion && \
      sudo systemctl enable salt-minion'
  done

# Accept all keys
  echo -e "${BLUE}\nAccept salt keys from vms...${NC}"
  salt-key -A -y

# Run highstate on all other nodes
  echo -s "${BLUE}\nRun highstate on all vms...${NC}"
  salt 'compunaut*' state.highstate
