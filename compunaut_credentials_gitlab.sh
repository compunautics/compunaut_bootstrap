#!/bin/bash

salt -I 'compunaut_salt:enabled:True' pillar.get compunaut:secrets:gitlab:gitlab_admin_user
salt -I 'compunaut_salt:enabled:True' pillar.get compunaut:secrets:gitlab:gitlab_admin_unencrypted_password
