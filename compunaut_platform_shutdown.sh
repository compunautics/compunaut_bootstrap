#!/bin/bash
### FUNCTIONS
cd "${0%/*}"

salt -I 'compunaut_rundeck:enabled:True' cmd.run 'shutdown now'
sleep 75
salt -C 'not I@compunaut_kvm:enabled:True' cmd.run "shutdown now"
sleep 75
salt -I 'compunaut_kvm:enabled:True' cmd.run 'shutdown now'
