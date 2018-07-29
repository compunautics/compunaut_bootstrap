#!/bin/bash
set -e

# Echo warning to users
        echo -e "#####\nThis script should be run as the root user of your intended ubuntu 16.04 hypervisor server.\n#####"

# Update sudoers so that sudo group members don't need a password
	sed -ri 's/^\%sudo\s+ALL=\(ALL:ALL\)+\sALL$/\%sudo\tALL=\(ALL:ALL\)\ NOPASSWD:ALL/g' /etc/sudoers

# Set up hostname
	hostnamectl set-hostname salt01
	if [[ ! `grep -P '127.0.1.1\s+salt01' /etc/hosts` ]]; then  
		echo "127.0.1.1 salt01" | tee -a /etc/hosts
	fi

# Update Everything
        apt-get update
        apt-get dist-upgrade -y

# Install Salt Master and Minion
	wget -O - https://repo.saltstack.com/apt/ubuntu/16.04/amd64/latest/SALTSTACK-GPG-KEY.pub | sudo apt-key add -
	if [[ ! -f /etc/apt/sources.list.d/saltstack.list ]]; then
          echo "deb http://repo.saltstack.com/apt/ubuntu/16.04/amd64/latest xenial main" | tee -a /etc/apt/sources.list.d/saltstack.list
        fi
	apt-get update
	apt-get install salt-master salt-minion git -y
        apt autoremove -y

# Configure Salt Minion to talk to local master
	sed -ri 's/^127.0.0.1\s+localhost$/127.0.0.1\tlocalhost\ salt/g' /etc/hosts
	salt-key -A -y

# Clone Salt Repos
        # Compunaut specific formulas
	mkdir -pv /srv/{salt,pillar,repos}
        if [[ ! -d /srv/repos/compunaut_default ]]; then
          git clone https://github.com/compunautics/compunaut_default.git /srv/repos/compunaut_default
	elif [[ ! -d /srv/repos/compunaut_hypervisor ]]; then
          git clone https://github.com/compunautics/compunaut_hypervisor.git /srv/repos/compunaut_hypervisor
        elif [[ ! -d /srv/repos/compunaut_top ]]; then
          git clone https://github.com/compunautics/compunaut_top.git /srv/repos/compunaut_top
        fi

        # Fetch all repos to ensure they're up to date
        (cd /srv/repos/compunaut_default && git pull)
        (cd /srv/repos/compunaut_hypervisor && git pull)
        (cd /srv/repos/compunaut_top && git pull)

# Link Repos to Appropriate places in /srv
        # Compunaut specific formulas
        if [[ ! -L /srv/salt/compunaut_default ]]; then
          ln -s /srv/repos/compunaut_default/salt /srv/salt/compunaut_default
        elif [[ ! -L /srv/salt/compunaut_hypervisor ]]; then
          ln -s /srv/repos/compunaut_hypervisor/salt /srv/salt/compunaut_hypervisor
        elif [[ ! -L /srv/pillar/compunaut_hypervisor ]]; then
          ln -s /srv/repos/compunaut_hypervisor/pillar /srv/pillar/compunaut_hypervisor
        elif [[ ! -L /srv/salt/top.sls ]]; then
          ln -s /srv/repos/compunaut_top/top.sls /srv/salt/top.sls
        fi

# Download cloud images
        #if [[ ! -f /srv/repos/compunaut_hypervisor/salt/images/xenial-server-cloudimg-amd64-disk1.img ]]; then
         # wget -O /srv/repos/compunaut_hypervisor/salt/images/xenial-server-cloudimg-amd64-disk1.img http://cloud-images.ubuntu.com/xenial/20180724/xenial-server-cloudimg-amd64-disk1.img
        #fi
