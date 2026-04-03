# virbian-builder

A repeatable Debian VM image builder for VirtualBox.

The project can build the appropriate image for both x86_64 and arm64 platforms (e.g., for running on macOS with Apple Silicon).


## Resulting VM Specification

- **Base**: Debian 13 (Trixie) netinst
- **Disk**: 8 GB
- **User**: `user` / `user` (with passwordless sudo, auto-login on tty1)
- **Desktop Environment**: X.Org, Openbox and tint2
- **Applications**: Firefox ESR, Thunderbird, Wireshark, vim, xfce4-terminal, mc
- **Development Tools**: gcc/g++, make, cargo, rustc, python
- **Networking Tools**: arp-scan, bind9-dnsutils, dhcpcd, ethtool, frr, iperf3, netcat, net-tools, tcpdump, telnet, traceroute
- **Network Configuration**:
  - IP forwarding enabled
  - Responds to broadcast ICMP echo requests
  - inetd echo and daytime services enabled
- **SSH**: Disabled by default (enable manually with `sudo systemctl start ssh`)
- **VirtualBox Guest Additions**
- **Locales**: en_US.UTF-8, en_GB.UTF-8, pl_PL.UTF-8


## Project Structure

```
virbian-builder/
├── README.md
├── tools/
│   ├── add-to-vb.sh                   # Creates and registers a VM in VirtualBox
│   └── remove-from-vb.sh              # Unregisters and deletes the VM
└── build-system/
    ├── virbian.pkr.hcl                # Packer configuration
    ├── virbian.auto.pkrvars.hcl       # Build settings (architecture, memory, cpus)
    ├── setup.sh                       # Post-install provisioning script
    ├── http/
    │   └── preseed.cfg                # Debian preseed for automated installation
    └── files/                         # Files copied verbatim into the VM
```


## Prerequisites

- [Packer](https://www.packer.io/) (>= 1.7.0)
- [VirtualBox](https://www.virtualbox.org/) (>= 7.2)


### Linux: Disable KVM modules

On Linux, KVM modules may conflict with VirtualBox. Before building, unload them:

```bash
sudo modprobe -r kvm_intel kvm_amd kvm
```


## Usage

All commands should be run from the `build-system/` folder.

The commands below will overwrite `~/builds/`. Without `-force`, the build fails if `~/builds/` already exists (remove it manually first).

1. Initialize Packer plugins:
   ```bash
   packer init virbian.pkr.hcl
   ```

2. Either build the image with automatic architecture detection:
   ```bash
   packer build -var "arch=$(uname -m)" -force .
   ```

3. Or configure architecture in `virbian.auto.pkrvars.hcl` by setting `arch` to `"x86_64"` or `"arm64"` (default is `x86_64`) and then build the image:

   ```bash
   packer build -force .
   ```

You may also adjust `memory` and `cpus` in `virbian.auto.pkrvars.hcl` for weaker build machines.

The resulting VM image will be placed in `~/builds/`:
- `virbian-x86_64-build-disk001.vmdk` — x86_64 architecture
- `virbian-arm64-build-disk001.vmdk` — arm64 architecture (Apple Silicon)


### How It Works

1. Packer creates a VM and boots the Debian ISO
2. `boot_command` sends keystrokes to load the preseed URL
3. Debian installs unattended using `http/preseed.cfg`
4. VM reboots, Packer connects via SSH
5. `setup.sh` runs: installs packages, Guest Additions, and applies system configuration
6. VM shuts down, Packer exports the VMDK (OVF and NVRAM files are removed)


## Registering in VirtualBox

You can create the machine manually in the VirtualBox GUI and add `~/builds/virbian-<arch>-disk001.vmdk` as medium. Or you can use scripts in `tools/` folder for automation. Replace `<arch>` by `x86_64` by `arm64` in the instructions below.

> **Warning:** The scripts in `tools/` are half-baked and should be used at your own risk. They are provided as a convenience and may not work in all environments. Read their source before running them.

> **Warning:** In particular, it's not possible to create more than one machine using this script. Use cloning mechanism in VirtualBox GUI if you need this feature.



Use `add-to-vb.sh` to copy the VMDK to `~/temp/` (with a timestamp) and register a new VM:

```bash
./tools/add-to-vb.sh ~/builds/virbian-<arch>-build-disk001.vmdk
```

The resulting VM is configured with:
- 1 CPUs, 2 GB RAM
- EFI firmware, VMSVGA graphics
- NAT networking with SSH forwarded to host port `2222` of local machine
- Shared folder: `~/Downloads` on the host, mountable as `Downloads` in guest
- Bidirectional clipboard

To start the VM and connect via SSH:
```bash
VBoxManage startvm virbian-<arch>
ssh user@localhost -p 2222
```

To mount the `Downloads` folder in the virtual machine:
```bash
mkdir ~/Downloads
sudo mount -t vboxsf -o uid=1000,gid=1000 Downloads ~/Downloads
```

To unregister and delete the VM:
```bash
./tools/remove-from-vb.sh
```

