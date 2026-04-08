#!/bin/zsh

# Script for adding the built machine to VirtualBox.
# It runs on
# - Linux on x86_64 architecture or
# - MacOS on arm64 architecture.
#
# To avoid accidentally modifying the original source medium, the script copies the source medium
# first to ~/temp/virbian-<timestamp>.{vdi|vmdk}.
#
# This script tries to mimic the setup that would be obtained by GUI creator in VirtualBox 7.2,
# for "Debian ARM 64-bit" / "Debian 64-bit" machines with EFI enabled.
#
# It ignores, however, the setting for audio and does not add controller for CD/DVD. 
# Additionally it:
# - enables bidirectional clipboard
# - enables NAT port forwarding for SSH
#
# As it is mainly intended for testing newly created builds, it removes existing keys for [127.0.0.1]:2222
# from ~/.ssh/known_hosts.


setopt errexit

if [[ -z $1 ]]; then
    print "Usage: $0 <source_medium>" >&2
    exit 1
fi

local source_medium=$1
local destination_medium=~/temp/virbian-$(date +%Y-%m-%d-%H-%M-%S).${source_medium:e}

local arch=$(uname -m)
local vm_name=virbian-$arch
local vm_folder=~/.config/VirtualBox\ VMs

if [[ $arch == "x86_64" ]]; then
    local ostype="Debian_64"
    local vram_size=16
elif [[ $arch == "arm64" ]]; then
    local ostype="Debian_arm64"
    local vram_size=128
else
    print "This script can run only on x86_64 or arm64" >&2
    exit 1
fi


VBoxManage createvm --name $vm_name --ostype $ostype --basefolder $vm_folder --register

VBoxManage modifyvm $vm_name \
    --firmware efi \
    --memory 2048 \
    --graphicscontroller vmsvga \
    --vram $vram_size \
    --mouse usbtablet \
    --clipboard bidirectional \
    --natpf1 "ssh,tcp,,2222,,22"

if [[ $arch == "x86_64" ]]; then
    VBoxManage modifyvm $vm_name \
        --usb-ehci on
    VBoxManage storagectl $vm_name --name StorageController --add sata --controller IntelAhci --portcount 1
else
    VBoxManage modifyvm $vm_name \
        --usb-ohci off \
        --usb-xhci on \
        --keyboard usb
    VBoxManage storagectl $vm_name --name StorageController --add virtio-scsi --portcount 1
    VBoxManage setextradata $vm_name GUI/ScaleFactor 2
fi

mkdir -p ~/temp
cp $source_medium $destination_medium
VBoxManage storageattach $vm_name --storagectl StorageController --port 0 --device 0 --type hdd --medium $destination_medium
VBoxManage modifymedium disk $destination_medium --type immutable
VBoxManage sharedfolder add $vm_name --name Downloads --hostpath ~/Downloads

ssh-keygen -f ~/.ssh/known_hosts -R '[127.0.0.1]:2222'

print "VM '$vm_name' created."
print "Start VM:  VBoxManage startvm $vm_name"
print "SSH:       ssh user@localhost -p 2222"
