#!/bin/bash

salt -I 'compunaut_salt:enabled:True' pillar.get compunaut:secrets:openldap:ldap_rootdn
salt -I 'compunaut_salt:enabled:True' pillar.get compunaut:secrets:openldap:ldap_unencrypted_rootpw
