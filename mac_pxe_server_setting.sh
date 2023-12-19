# PXE server setting on MAC
#https://docs.oracle.com/cd/E19140-01/821-2242/p53.html#scrolltoc
#https://andrewpage.tistory.com/73
#https://apple.stackexchange.com/questions/248785/mac-dhcp-server

# 1. DHCMASQ server setting (Small DHCP)
#https://apple.stackexchange.com/questions/248785/mac-dhcp-server
brew install isc-dhcp
cat > /opt/homebrew/etc/dhcpd.conf << EOF
# dhcpd.conf
#
# Sample configuration file for ISC dhcpd
#

# option definitions common to all supported networks...
option domain-name "example.org";
option domain-name-servers ns1.example.org, ns2.example.org;

default-lease-time 600;
max-lease-time 7200;

# Use this to enble / disable dynamic dns updates globally.
#ddns-update-style none;

# If this DHCP server is the official DHCP server for the local
# network, the authoritative directive should be uncommented.
authoritative;

# Use this to send dhcp log messages to a different log file (you also
# have to hack syslog.conf to complete the redirection).
#log-facility local7;

# No service will be given on this subnet, but declaring it helps the 
# DHCP server to understand the network topology.

allow booting;
allow bootp;
allow unknown-clients;
 
subnet 192.168.10.0 netmask 255.255.255.0 {
  range           192.168.10.1 192.168.10.50;
  #option routers  10.10.12.1;
  #option broadcast-address 10.10.12.255;
  #option subnet-mask 255.255.255.0;
  #option domain-name-servers 10.10.100.2;
  get-lease-hostnames true;
  next-server     192.168.20.101;              ## NOTE: TFTP Server 주소를 설정
  filename        "pxelinux.0";             ## NOTE: Boot Image 정보를 설정
}

host geninusui-MacBookPro.local{
  hardware ethernet 00:e0:4c:36:13:b9
  fixed-address 192.168.20.101
}
EOF

# 2. TFTP server setting
#https://rick.cogley.info/post/run-a-tftp-server-on-mac-osx/
cd /private/
sudo rm -rf tftpboot
mkdir /Users/myuser/tftpboot
sudo ln -s /Users/myuser/tftpboot tftpboot
sudo launchctl unload -F /System/Library/LaunchDaemons/tftp.plist
sudo launchctl load -F /System/Library/LaunchDaemons/tftp.plist

# 3. NFS server setting
sudo cat > /etc/exports << EOF
/private/tftpboot -network 192.168.20.0 -mask 255.255.255.0
EOF
sudo nfsd restart

# 4. create the PXE installation image (CentOS7)
mkdir -p /private/tftpboot/centos7
wget http://mirror.kakao.com/centos/7.9.2009/isos/x86_64/CentOS-7-x86_64-DVD-2009.iso
#hdiutil convert -format UDRW -o CentOS-7-x86_64-DVD-2009.dmg CentOS-7-x86_64-DVD-2009.iso
mkdir iso
hdiutil attach -nomount CentOS-7-x86_64-DVD-2009.iso
mount -t cd9660 /dev/disk4 iso
cp -r iso/* /private/tftpboot/centos7
cp /private/tftpboot/centos7/images/pxeboot/{vmlinuz,initrd.img} /private/tftpboot/centos7

# 5. PXE setting
mkdir -p /private/tftpboot/pxelinux.cfg
wget https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/6.xx/syslinux-6.03.tar.gz
tar xfz syslinux-6.03.tar.gz
cp syslinux-6.03/bios/core/pxelinux.0 /private/tftpboot
cat > /private/tftpboot/pxelinux.cfg/default << EOF
default centos7
label centos7
kernel centos7/vmlinuz
append ksdevice=en6 console=tty0 load_ramdisk=1 initrd=centos7/initrd.img 
network ks=nfs:192.168.20.101:/private/tftpboot/centos7/ks.cfg
EOF
