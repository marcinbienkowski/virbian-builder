#!/bin/zsh

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

VBoxManage createvm --name $vm_name --basefolder $vm_folder --register

VBoxManage modifyvm $vm_name \
    --ostype Debian_64 \
    --firmware efi \
    --cpus 4 \
    --memory 8192 \
    --vram 16 \
    --graphicscontroller vmsvga \
    --boot1 disk --boot2 none --boot3 none --boot4 none \
    --rtcuseutc on \
    --mouse usbtablet \
    --clipboard bidirectional \
    --audio-controller ac97 \
    --audio-out on \
    --usb-ehci on \
    --nic1 nat \
    --natpf1 "ssh,tcp,,2222,,22"

if [[ $arch == "arm64" ]]; then
    VBoxManage setextradata $vm_name GUI/ScaleFactor 2
else
    VBoxManage modifyvm $vm_name \
        --pae off \
        --spec-ctrl on
fi

cp $source_medium $destination_medium
VBoxManage storagectl $vm_name --name SATA --add sata --controller IntelAhci --portcount 1
VBoxManage storageattach $vm_name --storagectl SATA --port 0 --device 0 --type hdd --medium $destination_medium

VBoxManage sharedfolder add $vm_name --name Downloads --hostpath ~/Downloads

ssh-keygen -f ~/.ssh/known_hosts -R '[127.0.0.1]:2222'

print "VM '$vm_name' created."
print "Start VM:  VBoxManage startvm $vm_name"
print "SSH:       ssh user@localhost -p 2222"
