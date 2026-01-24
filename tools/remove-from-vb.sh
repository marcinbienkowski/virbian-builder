#!/bin/zsh

setopt errexit

local arch=$(uname -m)
local vm_name=virbian-$arch

VBoxManage unregistervm $vm_name --delete
