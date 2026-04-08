#!/bin/bash

set -e


echo "=== Installing packages ==="

echo 'APT::Install-Recommends "false";' | sudo tee /etc/apt/apt.conf.d/99no-recommends

echo "wireshark-common wireshark-common/install-setuid boolean true" | sudo debconf-set-selections


sudo apt-get update

sudo DEBIAN_FRONTEND=noninteractive apt-get purge -y os-prober
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    arp-scan bash-completion bind9-dnsutils bzip2 cargo cmake curl debian-edu-artwork-softwaves dhcpcd dovecot-pop3d \
    ethtool firefox-esr frr g++ hsetroot htop iperf3 linux-headers-$(uname -r) make man-db manpages mc \
    netcat-traditional net-tools obconf openbox openbsd-inetd postfix python3 python3-flask rustc telnet tcpdump \
    thunderbird time tint2 traceroute vim wireshark xinit xfce4-terminal x11-xserver-utils xserver-xorg-core \
    xserver-xorg-input-all xz-utils


echo "=== Installing Virtualbox Guest Additions ==="

sudo mount -o loop,ro /home/user/VBoxGuestAdditions.iso /mnt
if [ $(uname -m) = "aarch64" ]; then
    sudo /mnt/VBoxLinuxAdditions-arm64.run || true
else
    sudo /mnt/VBoxLinuxAdditions.run || true
fi
sudo umount /mnt
rm /home/user/VBoxGuestAdditions.iso


echo "=== System-level config ==="

sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=1"/' /etc/default/grub
sudo sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=1/' /etc/default/grub
sudo update-grub

sudo sed -i 's/^AcceptEnv.*/#&/' /etc/ssh/sshd_config

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


echo "=== Color prompts ==="

tee -a /home/user/.bashrc << 'EOF'
source /usr/local/bin/set_color_prompt.sh
EOF

sudo tee -a /root/.bashrc << 'EOF'
source /usr/local/bin/set_color_prompt.sh
EOF


echo "=== Final cleanup ==="

sudo systemctl disable dovecot.service frr.service postfix.service ssh.service
sudo systemctl mask dhcpcd.service ifup@.service

sudo apt-get purge -y linux-headers-$(uname -r)
sudo apt-get autopurge -y
sudo apt-get clean
sudo rm -rf /tmp/* /var/lib/apt/lists/* /var/log/* /var/tmp/*
sudo ln -s /usr/share/doc/systemd/README.logs /var/log/README

echo "=== Setup complete ==="
