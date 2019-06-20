#!/bin/bash

salt -I 'compunaut_salt:enabled:True' pillar.get compunaut:secrets:rundeck:rundeck_admin_user
salt -I 'compunaut_salt:enabled:True' pillar.get compunaut:secrets:rundeck:rundeck_admin_unencrypted_password
