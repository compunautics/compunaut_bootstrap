#!/bin/bash
set -e

# Echo warning to users
  echo -e "#####\nThis script should be run as the root user of your intended ubuntu 16.04 hypervisor server.\n#####"
  sleep 5

# Update sudoers so that sudo group members don't need a password
  sed -ri 's/^\%sudo\s+ALL=\(ALL:ALL\)+\sALL$/\%sudo\tALL=\(ALL:ALL\)\ NOPASSWD:ALL/g' /etc/sudoers

# Set up hostname
  hostnamectl set-hostname salt01
  if [[ ! `grep -P '127.0.1.1\s+salt01' /etc/hosts` ]]; then  
    echo "127.0.1.1 salt01" | tee -a /etc/hosts
  fi

# Update Everything
  apt-get -qq update
  apt-get -q dist-upgrade -y

# Install Salt Master and Minion
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
  apt autoremove -y

# Configure Salt Minion to talk to local master
  sed -ri 's/^127.0.0.1\s+localhost$/127.0.0.1\tlocalhost\ salt/g' /etc/hosts
  salt-key -A -y

# Clone and Link Compunaut Salt Repos
  # Create base salt directories
  mkdir -pv /srv/{salt,salt-images,pillar,repos}

  # Define compunaut formulas in array
  compunaut_repos=( compunaut_default compunaut_hypervisor compunaut_top )
        
  # Clone and link
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
  salt '*' state.highstate

# Log into vms and configure salt
  # vpn01
  sshpass -p C0mpun4ut1cs! ssh -l compunaut 172.16.0.2 "hostnamectl set-hostname compunaut-vpn01 && sed -ri 's/compunaut-minion/compunaut-vpn01\n172.16.0.1\tsalt/g' && systemctl start salt-minion"
  # vpn02
  sshpass -p C0mpun4ut1cs! ssh -l compunaut 172.16.0.3 "hostnamectl set-hostname compunaut-vpn02 && sed -ri 's/compunaut-minion/compunaut-vpn02\n172.16.0.1\tsalt/g' && systemctl start salt-minion"
