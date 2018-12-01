#!/bin/bash

salt '*rundeck*' pillar.get compunaut:global_vars:rundeck_admin_user
salt '*rundeck*' pillar.get compunaut:global_vars:rundeck_admin_unencrypted_password
