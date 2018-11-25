#!/bin/bash
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

### SALT REPO SETUP
# Clone and Link Compunaut Salt Repos
  # Create base salt directories
  echo_blue "Creating salt directories"
  mkdir -pv /srv/{salt,salt-images,pillar}
  mkdir -pv /srv/salt/{_states,_modules}

  # Clone and link
  echo_blue "Cloning/fetching Compunaut repos from Github and setting up local directories"
  # Clone repos
  if [[ ! -d /srv/repos ]]; then
    git clone https://github.com/compunautics/compunaut.git /srv/repos
    (cd /srv/repos && git submodule init)
  fi
  (cd /srv/repos && git pull && git submodule update --init --remote)
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
  echo_blue "Linking saltstack formulas"
  for formula in $(ls /srv/repos/ | grep -Pv 'LICENSE|compunaut'); do
    # Clone repos
    sls_dir=$(cut -d- -f1 <<< ${formula})
    # Link salt dirs
    if [[ ! -L /srv/salt/${sls_dir} ]]; then
      ln -s /srv/repos/${formula}/${sls_dir} /srv/salt/${sls_dir}
    fi
    # Copy _states and _modules
    if [[ -d /srv/repos/${formula}/_states ]]; then 
      rsync -avP /srv/repos/${formula}/_states/ /srv/salt/_states/
    fi
    if [[ -d /srv/repos/${formula}/_modules ]]; then
      rsync -avP /srv/repos/${formula}/_modules/ /srv/salt/_modules/ 
    fi
  done

  # Top is handled outside the loop
  if [[ ! -L /srv/salt/top.sls ]]; then
    ln -s /srv/repos/compunaut_top/salt_top.sls /srv/salt/top.sls
  fi
  if [[ ! -L /srv/pillar/top.sls ]]; then
    ln -s /srv/repos/compunaut_top/pillar_top.sls /srv/pillar/top.sls
  fi
