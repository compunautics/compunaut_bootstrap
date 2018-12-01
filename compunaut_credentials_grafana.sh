#!/bin/bash

salt '*monitor*' pillar.get compunaut:global_vars:grafana_admin_user
salt '*monitor*' pillar.get compunaut:global_vars:grafana_unencrypted_admin_password
