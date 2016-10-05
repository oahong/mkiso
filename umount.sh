#! /bin/bash

workdir=/work/squashfs-root

if [[ -f /.dockerenv || $(hostnamectl  | grep -wqs 'Chassis: container') -eq 0 ]] ; then
	if [[ -e ${workdir}/boot.cfg ]] ; then
		umount -v ${workdir}/boot
	fi

	if [[ -d  $workdir/dev/pts ]] ; then
		for mp in ${workdir}/{proc,sys,dev/pts,dev} ; do
			umount -v $mp
		done 
	fi
else
	echo "You should run the script in docker container"
	exit 1
fi
