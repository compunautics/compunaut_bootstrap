#!/bin/bash

salt '*rundeck*' pillar.get rundeck:username
salt '*rundeck*' pillar.get rundeck:password
