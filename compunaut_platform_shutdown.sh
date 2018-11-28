#!/bin/bash

salt -C '*salt* or *kvm*' cmd.run '/root/compunaut_bootstrap/compunaut_vm_shutdown.sh'
sleep 60
salt -C '*salt* or *kvm*' cmd.run 'shutdown now'
