#!/bin/bash
### FUNCTIONS
cd "${0%/*}"
source ./compunaut_functions

update_data

salt '*' saltutil.sync_all -b10 --batch-wait 20
