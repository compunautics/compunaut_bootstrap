#!/bin/bash

for vm in $(virsh list | awk '/compunaut/ {print $2}'); do
  virsh start ${vm}
done
