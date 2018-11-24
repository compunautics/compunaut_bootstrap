#!/bin/bash

salt '*gitlab*' pillar.get gitlab:server:initial_root_password
