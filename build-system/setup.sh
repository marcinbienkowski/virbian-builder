#!/bin/bash

set -e


echo "=== Installing packages ==="

echo 'APT::Install-Recommends "false";' | sudo tee /etc/apt/apt.conf.d/99no-recommends

echo "wireshark-common wireshark-common/install-setuid boolean true" | sudo debconf-set-selections
echo "postfix postfix/mailname string mail.example.com" | sudo debconf-set-selections

sudo apt-get update

sudo DEBIAN_FRONTEND=noninteractive apt-get purge -y os-prober
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    arp-scan bash-completion bind9-dnsutils bzip2 cargo cmake curl debian-edu-artwork-softwaves dhcpcd dovecot-pop3d \
    ethtool firefox-esr frr g++ gnupg hsetroot htop iperf3 linux-headers-$(uname -r) make man-db manpages mc \
    netcat-openbsd net-tools nmap obconf openbox openbsd-inetd postfix python3 python3-flask rustc telnet tcpdump \
    thunderbird time tint2 traceroute trickle vim wireshark xinit xfce4-terminal x11-xserver-utils xserver-xorg-core \
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

sudo sed -i 's|GRUB_CMDLINE_LINUX_DEFAULT="quiet"|GRUB_CMDLINE_LINUX_DEFAULT="loglevel=1"|' /etc/default/grub
sudo sed -i 's|GRUB_TIMEOUT=5|GRUB_TIMEOUT=1|' /etc/default/grub
sudo update-grub

sudo sed -i 's|^AcceptEnv.*|#&|' /etc/ssh/sshd_config

sudo usermod -aG wireshark user

sudo sed -i '/^#echo/s|^#||' /etc/inetd.conf
sudo sed -i '/^#daytime/s|^#||' /etc/inetd.conf

echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/10-ip-forward.conf
echo 'net.ipv4.icmp_echo_ignore_broadcasts = 0' | sudo tee /etc/sysctl.d/10-icmp_echo.conf

sudo openssl req -new -x509 -days 3650 -nodes -out /etc/ssl/certs/postfix.pem \
    -keyout /etc/ssl/private/postfix.key -subj "/CN=mail.example.com"
SSL_FINGERPRINT=$(openssl x509 -in /etc/ssl/certs/postfix.pem -fingerprint -sha256 -noout | cut -d= -f2)
sudo postconf -e "smtpd_tls_cert_file = /etc/ssl/certs/postfix.pem"
sudo postconf -e "smtpd_tls_key_file = /etc/ssl/private/postfix.key"

sudo ln -s /usr/lib/$(uname -m)-linux-gnu/trickle /usr/lib  # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1111118

for i in etc usr; do
    chmod -R a+r /home/user/$i
    sudo cp -r /home/user/$i/. /$i/
    rm -rf /home/user/$i
done


echo "=== Virtual mailboxes config ==="

test $(id -u mail) -eq 8

sudo mkdir -p /var/mail/vhosts/mail.example.com
sudo chown -R mail:mail /var/mail/vhosts

sudo postconf -e "mydestination=virbian.local, localhost.local, localhost"
sudo postconf -e "virtual_mailbox_domains = mail.example.com"
sudo postconf -e "virtual_mailbox_base = /var/mail/vhosts"
sudo postconf -e "virtual_mailbox_maps = texthash:/etc/postfix/vmailbox"
sudo postconf -e "virtual_minimum_uid = 8"
sudo postconf -e "virtual_uid_maps = static:8"
sudo postconf -e "virtual_gid_maps = static:8"

sudo sed -i '/^!include auth-system.conf.ext/s|^|#|' /etc/dovecot/conf.d/10-auth.conf
echo '!include auth-custom.conf.ext' | sudo tee -a /etc/dovecot/conf.d/10-auth.conf
sudo sed -i '/^ssl = /s|= .*|= no|' /etc/dovecot/conf.d/10-ssl.conf

sudo sed -i '/^mail_driver = /s|= .*|= maildir|' /etc/dovecot/conf.d/10-mail.conf
sudo sed -i '/^mail_path = /s|= .*|= /var/mail/vhosts/%{user\|domain}/%{user\|username}|' /etc/dovecot/conf.d/10-mail.conf
sudo sed -i '/^mail_home/d' /etc/dovecot/conf.d/10-mail.conf
sudo sed -i '/^mail_inbox_path/d' /etc/dovecot/conf.d/10-mail.conf


echo "=== User-level config ==="

echo 'source /usr/local/bin/set_color_prompt.sh' | sudo tee -a /root/.bashrc
echo 'source /usr/local/bin/set_color_prompt.sh' >> /home/user/.bashrc

mkdir -p /home/user/.thunderbird/default
echo "mail.example.com:25: OID.2.16.840.1.101.3.4.2.1 ${SSL_FINGERPRINT}" > /home/user/.thunderbird/default/cert_override.txt


echo "=== Final cleanup ==="

sudo systemctl disable dovecot.service frr.service postfix.service ssh.service
sudo systemctl mask dhcpcd.service ifup@.service

sudo apt-get purge -y linux-headers-$(uname -r)
sudo apt-get autopurge -y
sudo apt-get clean
sudo rm -rf /tmp/* /var/lib/apt/lists/* /var/log/* /var/tmp/*
sudo ln -s /usr/share/doc/systemd/README.logs /var/log/README

echo 'domain local' | sudo tee /etc/resolv.conf
echo 'domain local' | sudo tee /etc/resolv.conf.tail

echo "=== Setup complete ==="
