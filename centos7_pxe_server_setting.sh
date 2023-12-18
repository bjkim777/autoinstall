#https://nirsa.tistory.com/89
#https://andrewpage.tistory.com/73
TFTPBOOT_PATH="/data/tftpboot"
FTP_CENTOS7_PATH="/var/ftp/pub/centos7"
IP="10.10.10.1"
NETMASK="255.255.255.0"

# CentOS7
# 1. TFTP setting
yum install -y tftp tftp-server xinetd
sed -i 's/disable                 = yes/disable                 = no/g;s/server_args             = -s \/usr\/lib\/tftpboot/server_args             = -s '${TFTPBOOT_PATH}'' /etc/xinet.d/tftp
systemctl restart xinetd

# 2. DHCP setting
yum install -y dhcp
cat > /etc/dhcp/dhcpd.conf << EOF
allow booting;
allow bootp;
default-lease-time 600;
max-lease-time 7200;
option domain-name-servers 8.8.8.8;
option ip-forwarding false;
option mask-supplier false;
ddns-update-style none;
next-server $IP;
filename "pxelinux.0";

subnet ${IP%.*}.0 netmask $NETMASK {
        #option routers $IP;
        range ${IP%.*}.2 ${IP%.*}.200;
}

EOF
service dhcpd restart

: << "END"
# 3. NFS setting
yum install -y nfs-utils
cat > /etc/exports << EOF
$TFTPBOOT_PATH/ks ${IP%.*}.*(ro)
$TFTPBOOT_PATH/centos7 ${IP%.*}.*(ro)
EOF
service nfs restart
END

# 4. pxe setting
#yum install -y syslinux
#cp /usr/share/syslinux/{pxelinux.0,menu.c32} ${TFTPBOOT_PATH}
wget https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/6.xx/syslinux-6.03.tar.gz
tar xfz syslinux-6.03.tar.gz
cp syslinux-6.03/bios/core/pxelinux.0 ${TFTPBOOT_PATH}
cp syslinux-6.03/bios/com32/menu/menu.c32 ${TFTPBOOT_PATH}
mkdir -p ${TFTPBOOT_PATH}/pxelinux.cfg
cat > ${TFTPBOOT_PATH}/pxelinux.cfg/default << EOF
DEFAULT menu.c32
timeout 100

menu title ### OS Installer Boot Menu ###

LABEL CentOS7
	kernel centos7/vmlinuz
	#append ksdevice=link load_ramdisk=1 initrd=centos7/initrd.img unsupported_hardware text network ks=nfs:$IP:$TFTPBOOT_PATH/ks/ks.cfg text
    append initrd=centos7/initrd.img inst.repo=ftp://$IP/pub/centos7 ks=ftp://$IP:/pub/centos7/ks.cfg
EOF
wget https://mirror.kakao.com/centos/7.9.2009/isos/x86_64/CentOS-7-x86_64-DVD-2009.iso
mount -o loop CentOS-7-x86_64-DVD-2009.iso /mnt/
mkdir -p ${FTP_CENTOS7_PATH}
cp -r /mnt/* ${FTP_CENTOS7_PATH}
cp ${FTP_CENTOS7_PATH}/images/pxeboot/{initrd.img,vmlinuz} ${FTP_CENTOS7_PATH}

# kickstart file 
cat > ${FTP_CENTOS7_PATH}/ks.cfg << EOF
#platform=x86, AMD64, or Intel EM64T
#version=DEVEL
# Install OS instead of upgrade
install
# Keyboard layouts
keyboard 'us'
# Root password
rootpw --iscrypted $1$6Q2rlvvl$qmih2rSBWeykdfh/nUIYc1
# System language
lang en_US
# System authorization information
auth  --useshadow  --passalgo=sha512 #--enablenis --nisdomain=geninus --nisserver=192.168.20.92
# Use CDROM installation media
#cdrom
# Use text mode install
text
firstboot --disable
# SELinux configuration
selinux --disabled


# Firewall configuration
firewall --disabled
# Reboot after installation
reboot
# System timezone
timezone Asia/Seoul
# System bootloader configuration
#bootloader --location=partition
bootloader --append=" crashkernel=auto" --location=mbr --boot-drive=sda
# Partition clearing information
clearpart --all --initlabel
# Disk partitioning information
part /boot --asprimary --fstype="xfs" --ondisk=sda --size=1024
part /boot/efi --asprimary --fstype="xfs" --ondisk=sda --size=200
part swap --asprimary --fstype="swap" --ondisk=sda --size=8192
part / --asprimary --fstype="xfs" --grow --ondisk=sda --size=1

# Use network installation
url --url="ftp://$IP/pub/centos7"
EOF

# firewall down
systemctl stop firewalld
setenforce 0