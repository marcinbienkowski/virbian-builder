#!/bin/zsh

setopt errexit

source ${0:A:h}/virbian-config.sh

local clones=($(VBoxManage list vms | grep -oP "(?<=\")${clone_prefix}[^\"]+"))
for clone in $clones; do
    VBoxManage controlvm "$clone" poweroff 2>/dev/null || true
    VBoxManage unregistervm "$clone" --delete
    print "Deleted clone: $clone"
done

VBoxManage unregistervm "$vm_name" --delete
