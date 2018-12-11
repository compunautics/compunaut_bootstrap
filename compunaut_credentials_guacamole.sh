#!/bin/bash

salt '*netboot*' pillar.get compunaut:global_vars:guac_admin_user
salt '*netboot*' pillar.get compunaut:global_vars:guac_unencrypted_admin_password
