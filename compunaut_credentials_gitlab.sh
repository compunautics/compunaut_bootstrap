#!/bin/bash

salt '*gitlab*' pillar.get compunaut:global_vars:rundeck_admin_user
salt '*gitlab*' pillar.get compunaut:global_vars:rundeck_admin_unencrypted_password
