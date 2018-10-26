#!/bin/bash
# sourced from https://blog.zencoffee.org/2016/06/static-mac-generator-kvm/

date +%s | md5sum | head -c 6 | sed -e 's/\([0-9A-Fa-f]\{2\}\)/\1:/g' -e 's/\(.*\):$/\1/' | sed -e 's/^/52:54:00:/'; echo
