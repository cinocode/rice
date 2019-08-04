1. Partition

 - efi boot part size: 300mb + (25mb x number_of_bootable_snapshots)
 - put the rest in solaris root type partition
 - mkfs.fat -F32 /dev/sda1

2. Create the Pool

 - Check sector size: 
   - parted /dev/sda
   - (parted) print
   - Model: ATA VBOX HARDDISK (scsi)
   - Disk /dev/sda: 10.7GB
   - Sector size (logical/physical): 512B/512B <--- here
   - Partition Table: gpt
   - Should you have a 4k disk then add -o ashift=12 to the zpool create command.
 - Check device id with blkid /dev/sda2
 - (modprobe zfs)
 - export ZRPOOL=zmypool
 - touch /etc/zfs/${ZRPOOL}.cache
 - zpool create -o cachefile=/etc/zfs/${ZRPOOL}.cache -o autotrim=on -O acltype=posixacl -m none -R /mnt ${ZRPOOL} /dev/disk/by-id/INSERT_DISKID

3. Create the Datasets

 - zfs create -o mountpoint=none -o encryption=aes-256-gcm -o keyformat=passphrase ${ZRPOOL}/enc
 - zfs create -o mountpoint=none -o compression=lz4 ${ZRPOOL}/enc/co
 - zfs create -o mountpoint=none ${ZRPOOL}/enc/root
 - zfs create -o mountpoint=/ ${ZRPOOL}/enc/root/default
 - zfs create -o mountpoint=/home ${ZRPOOL}/enc/home
 - zfs create -o mountpoint=/var/cache/pacman/pkg ${ZRPOOL}/enc/co/pkg
 - zfs create -o mountpoint=/var/log -o com.sun:auto-snapshot=false ${ZRPOOL}/enc/co/log

 - zfs create -V 8G -b $(getconf PAGESIZE) -o compression=zle -o logbias=throughput -o sync=always -o primarycache=metadata -o secondarycache=none -o com.sun:auto-snapshot=false ${ZRPOOL}/enc/swap
 - mkswap -f /dev/zvol/${ZRPOOL}/enc/swap

4. Mount everything

 - zpool export ${ZRPOOL}
 - zpool import -l -R /mnt ${ZRPOOL}
 - blkid /dev/sda1
 - mkdir /mnt/boot
 - mount /dev/disk/by-uuid/UUID_OF_DISK /mnt/boot

5. Install Arch

 - Optimize mirror list
 - pacstrap -i /mnt base base-devel git sudo vim
 - genfstab -U -p /mnt | grep boot >> /mnt/etc/fstab
 - echo /dev/zvol/${ZRPOOL}/enc/swap none swap discard 0 0 >> /mnt/etc/fstab
 - delete zfs entries from /mnt/etc/fstab
 - arch-chroot
 - take care of locale / timezone / hostname / passwd
 - systemctl enable dhcpcd
 - if no lan access: pacman -S iw wpa_supplicant dialog

6. Enable Zfs on Fresh System

 - # /etc/pacman.conf:
 - #------------------
 - [archzfs]
 - Server = https://archzfs.com/$repo/$arch
 - pacman-key -r F75D9D76
 - pacman-key --lsign-key F75D9D76
 - pacman -Syy
 - pacman -S zfs-linux
 - export ZRPOOL=zmypool
 - zpool set cachefile=/etc/zfs/${ZRPOOL}.cache ${ZRPOOL}
 - check zpool cache for contents to be sure

7. Setup Mkinitcpio

 - Edit /etc/mkinitcpio.conf
 - HOOKS="base udev keyboard autodetect keymap modconf block zfs filesystems"
 - mkinitcpio -p linux

8. Enable Zfs Services
 - zfs set canmount=noauto ${ZRPOOL}/enc/root/default
 - systemctl enable zfs.target
 - systemctl enable zfs-import-cache
 - systemctl enable zfs-mount
 - systemctl enable zfs-import.target

9. Install Bootloader
 - pacman -S intel-ucode
 - bootctl install
 - /boot/loader/loader.conf
timeout 1
default arch
 - /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options zfs=zmypool/enc/root/default zfs_force=on rw
 - umount /mnt/boot
 - zpool export zroot
 - reboot

10. After the first boot

 - zgenhostid $(hostid)
 - zfs create -o mountpoint=/home/ole/music -o ${ZRPOOL}/enc/co/music
 - zfs create -o mountpoint=/home/ole/code_lz ${ZRPOOL}/enc/co/code_lz
 - zpool set cachefile=/etc/zfs/zpool.cache ${ZRPOOL}
 - mkinitcpio -p linux
 - /boot/loader/loader.conf
editor no

11. Setup Multiple Boot Environments

ZRPOOL=zmypool
ZROOT=${ZRPOOL}/enc/root

zfs snapshot ${ZROOT}/default@one
zfs snapshot ${ZROOT}/default@two
zfs snapshot ${ZROOT}/default@three

zfs clone ${ZROOT}/default@one ${ZROOT}/one
zfs clone ${ZROOT}/default@two ${ZROOT}/two
zfs clone ${ZROOT}/default@three ${ZROOT}/three

zfs set canmount=noauto ${ZROOT}/one
zfs set canmount=noauto ${ZROOT}/two
zfs set canmount=noauto ${ZROOT}/three

zfs set mountpoint=/ ${ZROOT}/one
zfs set mountpoint=/ ${ZROOT}/two
zfs set mountpoint=/ ${ZROOT}/three

cp /boot/vmlinuz-linux /boot/vmlinuz-linux-one
cp /boot/vmlinuz-linux /boot/vmlinuz-linux-two
cp /boot/vmlinuz-linux /boot/vmlinuz-linux-three

cp /boot/initramfs-linux.img /boot/initramfs-linux-one.img
cp /boot/initramfs-linux.img /boot/initramfs-linux-two.img
cp /boot/initramfs-linux.img /boot/initramfs-linux-three.img

 - /boot/loader/entries/barch.conf
title   Arch Linux (Latest Snapshot)
linux   /vmlinuz-linux-one
initrd  /intel-ucode.img
initrd  /initramfs-linux-one.img
options zfs=zmypool/enc/root/one zfs_force=on rw
 - /boot/loader/entries/carch.conf
title   Arch Linux (Prior Snapshot)
linux   /vmlinuz-linux-two
initrd  /intel-ucode.img
initrd  /initramfs-linux-two.img
options zfs=zmypool/enc/root/two zfs_force=on rw
 - /boot/loader/entries/darch.conf
title   Arch Linux (Oldest Snapshot)
linux   /vmlinuz-linux-three
initrd  /intel-ucode.img
initrd  /initramfs-linux-three.img
options zfs=zmypool/enc/root/three zfs_force=on rw

 - /usr/local/bin/zyay
#!/bin/bash
ZRPOOL=zmypool
ZROOT=${ZRPOOL}/enc/root

echo cycle initramfs
sudo rm /boot/initramfs-linux-three.img
sudo mv /boot/initramfs-linux-two.img /boot/initramfs-linux-three.img
sudo mv /boot/initramfs-linux-one.img /boot/initramfs-linux-two.img
sudo cp /boot/initramfs-linux.img /boot/initramfs-linux-one.img
# or
# sudo cp ~/.config/kernel/default/initramfs-default.img /boot/initramfs-linux-one.img
# sudo rm /boot/initramfs-linux-one.img
# sudo cp /boot/initramfs-linux.img /boot/initramfs-linux-one.img

echo cycle kernel
sudo rm /boot/vmlinuz-linux-three
sudo mv /boot/vmlinuz-linux-two /boot/vmlinuz-linux-three
sudo mv /boot/vmlinuz-linux-one /boot/vmlinuz-linux-two
sudo cp /boot/vmlinuz-linux /boot/vmlinuz-linux-one
# or
# sudo cp ~/.config/kernel/default/vmlinuz-default /boot/vmlinuz-default-one.img
# sudo rm /boot/vmlinuz-linux-one
# sudo cp /boot/vmlinuz-linux /boot/vmlinuz-linux-one

echo cycle snaps and clones
sudo zfs destroy -R ${ZROOT}/default@three
sudo zfs rename ${ZROOT}/default@two ${ZROOT}/default@three
sudo zfs rename ${ZROOT}/two ${ZROOT}/three
sudo zfs rename ${ZROOT}/default@one ${ZROOT}/default@two
sudo zfs rename ${ZROOT}/one ${ZROOT}/two

echo create new snap one
sudo zfs snapshot ${ZROOT}/default@one
sudo zfs clone ${ZROOT}/default@one ${ZROOT}/one
sudo zfs set canmount=noauto ${ZROOT}/one
sudo zfs set mountpoint=/ ${ZROOT}/one

echo update the system
sudo reflector --country France --country Germany --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
yay

echo report changes
sudo mkdir -p /var/log/upgrade
sudo zfs snapshot ${ZROOT}/default@upgrade
sudo zfs diff ${ZROOT}/default@one ${ZROOT}/default@upgrade | sudo tee "/var/log/upgrade/$(date +"%Y_%m_%d_%H_%M")_yay_diff.log" > /dev/null
sudo zfs destroy ${ZROOT}/default@upgrade

echo scrub pool
sudo zpool scrub ${ZRPOOL}

