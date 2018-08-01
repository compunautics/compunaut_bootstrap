#!/bin/bash

salt 'salt*' state.sls compunaut_hypervisor.reset
salt-key -d 'compunaut*'
