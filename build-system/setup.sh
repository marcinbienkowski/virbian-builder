#!/bin/bash

set -e


echo "=== Installing packages ==="

echo 'APT::Install-Recommends "false";' | sudo tee /etc/apt/apt.conf.d/99no-recommends

echo "wireshark-common wireshark-common/install-setuid boolean true" | sudo debconf-set-selections

sudo tee /etc/dpkg/dpkg.cfg.d/no-locales << 'EOF'
path-exclude=/usr/share/locale/*
path-include=/usr/share/locale/en*
path-include=/usr/share/locale/pl*
EOF

sudo apt-get update

sudo DEBIAN_FRONTEND=noninteractive apt-get purge -y os-prober
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    arp-scan bind9-dnsutils bzip2 cargo debian-edu-artwork-softwaves dhcpcd ethtool firefox-esr frr g++ \
    hsetroot iperf3 linux-headers-$(uname -r) make manpages mc netcat-traditional net-tools obconf openbox \
    openbsd-inetd python3 python3-flask rustc telnet tcpdump thunderbird tint2 traceroute vim wireshark xinit \
    xfce4-terminal x11-xserver-utils xserver-xorg-core xserver-xorg-input-all xz-utils


echo "=== Installing Virtualbox Guest Additions ==="

sudo mount -o loop,ro /home/user/VBoxGuestAdditions.iso /mnt
sudo /mnt/VBoxLinuxAdditions.run || true
sudo umount /mnt
rm /home/user/VBoxGuestAdditions.iso


echo "=== System-level config ==="

sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=1"/' /etc/default/grub
sudo sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/' /etc/default/grub
sudo update-grub

sudo usermod -aG wireshark user

sudo sed -i '/^#echo/s/^#//' /etc/inetd.conf
sudo sed -i '/^#daytime/s/^#//' /etc/inetd.conf

echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/10-ip-forward.conf
echo 'net.ipv4.icmp_echo_ignore_broadcasts = 0' | sudo tee /etc/sysctl.d/10-icmp_echo.conf

for i in etc usr; do
    chmod -R a+r /home/user/$i
    sudo cp -r /home/user/$i/. /$i/
    rm -rf /home/user/$i
done


echo "=== User config ==="

tee -a /home/user/.bashrc << 'EOF'
if [ -n "$SSH_CONNECTION" ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;31m\][REMOTE] \[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
fi
EOF


echo "=== Final cleanup ==="

sudo systemctl disable frr.service
sudo systemctl disable ssh.service
sudo systemctl mask dhcpcd.service
sudo systemctl mask ifup@.service

sudo apt-get purge -y linux-headers-$(uname -r)
sudo apt-get autopurge -y
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


echo "=== Setup complete ==="
