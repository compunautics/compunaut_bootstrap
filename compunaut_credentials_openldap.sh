#!/bin/bash

salt '*ldap*' pillar.get openldap:unencrypted_rootpw
salt '*ldap*' pillar.get openldap:rootdn
