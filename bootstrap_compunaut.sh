#!/bin/bash
set -e
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
	echo "deb http://repo.saltstack.com/apt/ubuntu/16.04/amd64/latest xenial main" | tee -a /etc/apt/sources.list.d/saltstack.list
	apt-get update
	apt-get install salt-master salt-minion git -y

# Configure Salt Minion to talk to local master
	sed -ri 's/^127.0.0.1\s+localhost$/127.0.0.1\tlocalhost\ salt/g' /etc/hosts
	salt-key -A -y

# Clone Salt Repos
	git clone https://github.com/compunautics/compunaut_hypervisor /srv/salt/compunaut_hypervisor

# Create top.sls file
#	echo -e "base:\n\ \ \'salt\*\':\n    \-\ compunaut_hypervisor" > /srv/salt/top.sls
