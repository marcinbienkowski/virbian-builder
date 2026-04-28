#!/bin/zsh

# Script for creating a linked clone of the VM created by add-to-vb.sh.
# The clone shares the base disk with the original VM and gets new MAC addresses.
#
# Usage: clone-vb.sh <int-net-1> [int-net-2] ...
#   Argument j (for 1 <= j <= 4) configures a network card j attached to "Internal Network"
#      named int-net-j.
#   If int-net-j is equal to "NAT", the network card j will be attached to NAT.


setopt errexit

if (( $# == 0 )); then
    print "Usage: $0 <int-net-1> [int-net-2] ..." >&2
    print "  int-net-j: internal network name or NAT" >&2
    exit 1
fi

source ${0:A:h}/virbian-config.sh
local source_vm=$vm_name
local clone_name=${clone_prefix}$(date +%Y-%m-%d-%H-%M-%S)

local snapshot_name=base
VBoxManage snapshot $source_vm take $snapshot_name 2>/dev/null || true

VBoxManage clonevm $source_vm \
    --options link \
    --snapshot $snapshot_name \
    --name $clone_name \
    --basefolder $vm_folder \
    --register

VBoxManage modifyvm $clone_name --natpf1 delete "ssh" 2>/dev/null || true

integer i=1
for network_name; do
    if [[ $network_name == "NAT" ]]; then
        VBoxManage modifyvm $clone_name --nic$i nat
    else
        VBoxManage modifyvm $clone_name --nic$i intnet --intnet$i $network_name
    fi
    (( i++ ))
done

print "Linked clone '$clone_name' created from '$source_vm'."
print "Start VM:  VBoxManage startvm $clone_name"
