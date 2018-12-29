#!/bin/bash

### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

### GET VARS
node_to_reset=${1}

### RESET DNSMASQ
minion_wait
echo_blue "Resetting dnsmasq"
salt "*${node_to_reset}*" cmd.run 'echo "interface=lo\nno-resolv\nport=53\nserver=209.244.0.3\nserver=209.244.0.4\nserver=1.1.1.1\nserver=1.0.0.1" > /etc/dnsmasq.conf && systemctl restart dnsmasq'
