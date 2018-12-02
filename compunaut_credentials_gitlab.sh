#!/bin/bash

salt '*gitlab*' pillar.get compunaut:global_vars:gitlab_admin_user
salt '*gitlab*' pillar.get compunaut:global_vars:gitlab_admin_unencrypted_password
