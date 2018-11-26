#!/bin/bash

salt -C '*salt* or *kvm*' cmd.run '/root/compunaut_bootstrap/compunaut_vm_startup.sh'
