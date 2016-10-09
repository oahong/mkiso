#! /bin/bash

tagver=1
workbase=/work
full_date=$(date +%F)
iso_dir=${workbase}/final/${full_date}
boot_entries=(
    ${workbase}/iso-boot/casper/boot
    ${workbase}/iso-boot/boot
)

if [[ -f /.dockerenv || $(hostnamectl  | grep -wqs 'Chassis: container') -eq 0 ]] ; then
	:
else
    echo "You should run the script in container"
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 2
fi

edo() {
    cmd=$@
    echo $cmd && $cmd
    [[ $? -ne 0 ]] && exit 3
}

get_build_id() {
    local bootcfg=$1
    tagver=$(awk '/^title/ { split($NF,a,"V" )  } END { print ++a[2]}' $bootcfg)
    if [[ $tagver -lt 100 ]] ; then
        tagver=107
    fi
}

# Pmon firmware: Append build id to boot.cfg
fix_bootcfg() {
    local bootcfg=${1}/boot.cfg

    #live boot
    sed -e "/Deepin/s@Live.*@Live Build ${tagver}@" -i $bootcfg
    #casper boot
    sed -e "/^title/s@Deepin.*@Deepin 15 for Loongson Build${tagver}@" -i $bootcfg
}

# Kunlun firmware: Append build id to grub.cfg
fix_grubcfg() {
    local grubcfg=${1}/grub.cfg

    #live boot
    sed -e "s/Deepin Live.*/Deepin Live Build ${tagver}/" -i $grubcfg
    #casper boot
    sed -e "s/Deepin.*for/Deepin 15 build ${tagver} for" -i $grubcfg
}

fix_buildid() {
    local build_os_release=${workbase}/squashfs-root/etc/os-release

    if [[ -e $build_os_release ]] ; then
        edo sed -e '/BUILD_ID/d' -i $build_os_release  
        echo $build_tag_str
        echo 'BUILD_ID="'$build_tag_str'"' >> $build_os_release
    fi
}

# umount pseudo-filesystem
source umount.sh

get_build_id ${workbase}/iso-boot/casper/boot/boot.cfg

for entry in ${boot_entries[@]} ; do
    fix_bootcfg $entry
    fix_grubcfg $entry
done

build_tag_str=${full_date}_v${tagver}
build_iso=deepin15_mipsel_${build_tag_str}.iso

fix_buildid

# run hooks
run-parts -v --report --exit-on-error ${workbase}/build-hooks

rm -vf ${workbase}/iso-boot/casper/filesystem.squashfs
edo mksquashfs  ${workbase}/squashfs-root/ ${workbase}/iso-boot/casper/filesystem.squashfs

xorriso -as mkisofs -r -V "Deepin 2015 mipsel" -o ./$build_iso -cache-inodes /work/iso-boot

#TODO: rewrite
if [[ -e $build_iso ]] ; then
    [[ -d $iso_dir ]] || mkdir -pv $iso_dir
    md5sum $build_iso  >>  MD5SUM
    mv $build_iso MD5SUM $iso_dir
    touch $iso_dir/ChangeLog
fi
# vim: set expandtab ts=4 sw=4:
