#! /bin/bash

workdir=/work/squashfs-root
isoboot=/work/iso-boot/casper/boot/

if [[ -f /.dockerenv || $(hostnamectl  | grep -wqs 'Chassis: container') -eq 0 ]] ; then
	if [[ ! -e ${workdir}/boot.cfg ]] ; then
		mount -v -o bind $isoboot ${workdir}/boot
	fi

	if [[ -d  $workdir/dev/pts ]] ; then
		echo "already mounted"
		exit 0
	else
		mount -vt proc none ${workdir}/proc
		mount -vt sysfs none ${workdir}/sys
		mount -v --bind /dev ${workdir}/dev
		mount -vt devpts none ${workdir}/dev/pts
	fi
else
	echo "You should run the script in docker or systemd container"
	exit 1
fi
