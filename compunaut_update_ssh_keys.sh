#!/bin/bash

salt 'salt*' state.apply compunaut_hypervisor.ssh
salt 'compunaut*' state.apply compunaut_default.ssh
