#!/bin/bash

salt '*rundeck*' pillar.get rundeck:user
salt '*rundeck*' pillar.get rundeck:password
