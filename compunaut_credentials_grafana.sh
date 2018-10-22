#!/bin/bash

salt '*monitor*' pillar.get grafana:server:admin
