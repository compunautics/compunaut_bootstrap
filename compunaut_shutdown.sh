#!/bin/bash

salt -C '*salt* or *kvm*' cmd.run '/root/compunaut_bootstrap/compunaut_vm_shutdown.sh'
sleep 120
salt -C '*salt* or *kvm*' cmd.run 'shutdown now'