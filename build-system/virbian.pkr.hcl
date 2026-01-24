packer {
    required_plugins {
        virtualbox = {
            version = ">= 1.0.0"
            source    = "github.com/hashicorp/virtualbox"
        }
    }
}


variable "home" { default = env("HOME") }
variable "memory" {}
variable "cpus" {}
variable "arch" {}

locals {
    iso_urls = {
        x86_64 = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.3.0-amd64-netinst.iso"
        arm64  = "https://cdimage.debian.org/debian-cd/current/arm64/iso-cd/debian-13.3.0-arm64-netinst.iso"
    }
    iso_checksums = {
        x86_64 = "sha256:c9f09d24b7e834e6834f2ffa565b33d6f1f540d04bd25c79ad9953bc79a8ac02"
        arm64  = "sha256:10aa125ac1a74de9366ba624e71fb892fbc2e7863be85e966973f43d018698a6"
    }
    guest_os_types = {
        x86_64 = "Debian_64"
        arm64  = "Debian_arm64"
    }
    kernel_paths = {
        x86_64 = "install.amd"
        arm64  = "install.a64"
    }
}


source "virtualbox-iso" "debian" {
    iso_url                = local.iso_urls[var.arch]
    iso_checksum           = local.iso_checksums[var.arch]

    output_directory       = "${var.home}/builds"
    output_filename        = "virbian-${var.arch}"
    vm_name                = "virbian-${var.arch}-build"
    guest_os_type          = local.guest_os_types[var.arch]
    guest_additions_mode   = "upload"

    disk_size              = 8192
    hard_drive_interface   = "sata"
    iso_interface          = "sata"
    firmware               = "efi"

    memory                 = var.memory
    cpus                   = var.cpus

    http_directory         = "http"
    boot_wait              = "10s"
    boot_keygroup_interval = "10ms"
    boot_command = [
        "c", "<wait1>",
        "linux /${local.kernel_paths[var.arch]}/vmlinuz auto=true priority=critical",
            " preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg",
            " netcfg/get_hostname=virbian",             # Must be here, is ignored in preseed.cfg.
        "<enter>", 
        "initrd /${local.kernel_paths[var.arch]}/initrd.gz", "<enter>",
        "boot", "<enter>"
    ]

    ssh_username           = "user"
    ssh_password           = "user"
    ssh_timeout            = "1h"
    shutdown_command       = "echo 'user' | sudo -S shutdown -P now"

    # USB 3.0 needed for Macs, does not hurt on Linux either.
    vboxmanage = [
        ["modifyvm", "{{.Name}}", "--usbohci", "off"],
        ["modifyvm", "{{.Name}}", "--usbehci", "off"],
        ["modifyvm", "{{.Name}}", "--usbxhci", "on"],
    ]
}


build {
    sources = ["source.virtualbox-iso.debian"]

    provisioner "file" {
        source      = "files/"
        destination = "/home/user"
    }

    provisioner "shell" {
        script = "setup.sh"
    }

    post-processor "shell-local" {
        inline = [
            "rm -f ${var.home}/builds/virbian-${var.arch}.ovf",
            "rm -f ${var.home}/builds/virbian-${var.arch}-build.nvram"
        ]
    }
}
