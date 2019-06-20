#!/bin/bash

salt -I 'compunaut_salt:enabled:True' pillar.get compunaut:secrets:guacamole:guac_admin_user
salt -I 'compunaut_salt:enabled:True' pillar.get compunaut:secrets:guacamole:guac_unencrypted_admin_password
