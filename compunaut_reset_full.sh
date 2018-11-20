#!/bin/bash

salt -C 'salt* or kvm*' state.sls compunaut_hypervisor.reset
salt-key -d 'compunaut*' -y
rm -rf /srv/*
