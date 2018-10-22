#!/bin/bash

for vm in $(virsh list --all | awk '/compunaut/ {print $2}'); do
  virsh start ${vm}
done
