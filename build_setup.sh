#!/bin/bash
# Automating building v0.1 05-12-17

PACKAGES=(screen unix2dos isomd5sum samba winbind samba-winbind authconfig)
SAMBADIR="/etc/samba"
NASDIR="/nas/scripts/config/build/"
BUILDTHOST=$(echo $HOSTNAME | cut -d"." -f1)

if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root." 
	exit 1
fi

if ! [ $PWD == "/root" ]; then
	echo "This script must be copied and run from the /root directory."
	exit 1
fi

if grep -q "SAN" /etc/fstab; then
	:
else
	printf "\n#SAN1            /media/SAN1      cvfs    rw,cachebufsize=2048k 0
    0\n#SAN2             /media/SAN2       cvfs
    rw,cachebufsize=512K,buffercache_readahead=1     0 0\n#SAN3
    /media/SAN3      cvfs    auto,cachebufsize=2048k                          0
    0\n#SAN4             /media/SAN4      cvfs    auto,cachebufsize=2048k
    0 0\n#SAN5             /media/SAN5      cvfs    auto,cachebufsize=2048k
    0 0\n#SAN6            /media/SAN6     cvfs    rw,cachebufsize=2048k                            0 0\n" >>/etc/fstab
	for SAN in $(cat /etc/fstab | grep "SAN" | awk '{print $1}' | cut -d"#" -f2); do
		if [ -d "/media/$SAN" ]; then
			:
		else
			mkdir "/media/$SAN"
		fi
	done
fi

if grep -q "nas" /etc/fstab && grep -q "das" /etc/fstab; then
	:
else
	echo "nas.example.com:/media/nas/data    /nas    nfs bg,intr,vers=3,rsize=16384,wsize=16384,defaults 0 0" >> /etc/fstab
	echo "das.example.com:/mnt/das	/mnt/das       nfs    intr,rsize=8192,wsize=8192,timeo=14,defaults     0 0" >> /etc/fstab
	if [ -d "/nas" ]; then
		:
	else
		mkdir "/nas"
	fi
	if [ -d "/mnt/das" ]; then
                :
        else
                mkdir "/mnt/das"
        fi

	mount -a >> /dev/null
fi

if [ $(mount | grep -q "nas") ] && [ $(mount | grep -q "das") ]; then
	cp "$NASDIR/sudoers_original" /etc/sudoers
	sed -i "s/ingesthostname/$BUILDHOST/g" /etc/sudoers
else
	echo "Nas and Das are not mounted check manually."
	exit 1
fi

echo "Setting up the repository.."
echo

if [-d "/etc/yum.repos.d/bak" ]; then
	:
else
	mkdir /etc/yum.repos.d/bak
	mv /etc/yum.repos.d/Cent* /etc/yum.repos.d/bak

cp "$NASDIR/example.repo" /etc/yum.repos.d
yum repolist

echo "Installing packages.."
echo

for PACKAGE in ${PACKAGES[@]}; do
	yum install -y $PACKAGE > /dev/null
done

echo "Setting up samba and winbind.."
echo

if rpm -qa | grep -q samba; then
	cp /nas/scripts/config/build/smb.conf /etc/samba
	chkconfig smb on
	chkconfig winbind on
	authconfig --enablemkhomedir --update
	service smb start
	service winbind start
else
	echo "Echo samba is not installed, check manually"
fi

echo "Setting up environment.."
echo

echo "export PATH=$PATH:/nas/scripts/bin" >> /etc/profile.d/scripts.sh
echo "export PATH=$PATH:/nas/scripts/lib/python" >> /etc/profile.d/scripts.sh
echo "export DEBUG=0" >> /etc/profile.d/scripts.sh
chmod 644 /etc/profile.d/scripts.sh

echo "Installing CVFS and Multipath.."
echo

cp "$NASDIR/snfs-client.RedHat60AS.x86_64.rpm" /tmp
cp "$NASDIR/snfs-common.RedHat60AS.x86_64.rpm" /tmp
cp "$NASDIR/ddn-multipath-toolsel6.x86_64.rpm" /tmp

chmod 744 /tmp/*.rpm

rpm -i /tmp/ddn-multipath.el6.x86_64.rpm
rpm -i /tpm/snfs-client.RedHat60AS.x86_64.rpm
rpm -i /tmp/snfs-common.RedHat60AS.x86_64.rpm

cp "$NASDIR/multipath.conf" /etc/

if [ -d "/usr/cvfs/config" ]; then
	printf "192.168.1.1\n192.168.1.2\n192.168.1.201\n192.168.1.202\n192.168.1.40" >> /usr/cvfs/config/fsnameservers
fi
