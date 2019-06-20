#!/bin/bash

salt -I 'compunaut_kvm:enabled:True' cmd.run '/root/compunaut_bootstrap/compunaut_vm_startup.sh'
