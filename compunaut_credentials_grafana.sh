#!/bin/bash

salt -I 'compunaut_salt:enabled:True' pillar.get compunaut:secrets:grafana:grafana_admin_user
salt -I 'compunaut_salt:enabled:True' pillar.get compunaut:secrets:grafana:grafana_unencrypted_admin_password
