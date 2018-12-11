#!/bin/bash

salt '*ldap*' pillar.get openldap:rootdn
salt '*ldap*' pillar.get openldap:unencrypted_rootpw
