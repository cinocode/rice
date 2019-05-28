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
 - touch /etc/zfs/zpool.cache
 - zpool create -o cachefile=/etc/zfs/zpool.cache -o autotrim=on -O acltype=posixacl -m none -R /mnt zmypool /dev/disk/by-id/INSERT_DISKID

3. Create the Datasets

 - zfs create -o mountpoint=none -o encryption=aes-256-gcm -o keyformat=passphrase zmypool/enc
 - zfs create -o mountpoint=none zmypool/enc/root
 - zfs create -o mountpoint=none -o compression=lz4 zmypool/enc/co
 - zfs create -o mountpoint=/ -o canmount=noauto -o zmypool/enc/root/default
 - zfs create -o mountpoint=/home -o zmypool/enc/home
 - zfs create -o mountpoint=/var/cache/pacman/pkg zmypool/enc/co/pkg
 - zfs create -o mountpoint=/var/log -o com.sun:auto-snapshot=false zmypool/enc/co/log

 - zfs create -V 4G -b $(getconf PAGESIZE) -o compression=zle -o logbias=throughput -o sync=always -o primarycache=metadata -o secondarycache=none -o com.sun:auto-snapshot=false zmypool/enc/swap
 - mkswap -f /dev/zvol/zmypool/enc/swap
 - echo /dev/zvol/zmypool/enc/swap none swap discard 0 0 >> /etc/fstab

4. Mount everything

 - zpool export zmypool
 - zpool import -l -R /mnt zmypool
 - blkid /dev/sda1
 - mkdir /mnt/boot
 - mount /dev/disk/by-uuid/UUID_OF_DISK /mnt/boot

5. Install Arch

 - Optimize mirror list
 - pacstrap -i /mnt base base-devel git sudo vim
 - genfstab -U -p /mnt | grep boot >> /mnt/etc/fstab
 - delete zfs entries from /mnt/etc/fstab
 - zpool set cachefile=/etc/zfs/zpool.cache zmypool
 - cp /etc/zfs/zpool.cache /mnt/etc/zfs/zpool.cache
 - arch-chroot
 - take care of locale / timezone / hostname / passwd
 - systemctl enable dhcpcd
 - if no lan access: pacman -S iw wpa_supplicant dialog

6. Enable Zfs on Fresh System

 - # /etc/pacman.conf:
 - #------------------
 - [archzfs]
 - Server = http://archzfs.com/$repo/x86_64
 - pacman-key -r 0ee7a126
 - pacman-key --lsign-key 0ee7a126
 - pacman -Syy
 - pacman -S zfs-linux
 - zpool set cachefile=/etc/zfs/zpool.cache zmypool
 - check zpool cache for contents to be sure

7. Setup Mkinitcpio

 - Edit /etc/mkinitcpio.conf
 - HOOKS="base udev keyboard autodetect keymap modconf block zfs filesystems"
 - mkinitcpio -p linux

8. Enable Zfs Services
 - systemctl enable zfs.target
 - systemctl enable zfs-import-cache
 - systemctl enable zfs-mount
 - systemctl enable zfs-import.target

9. Install Bootloader
 - bootctl install
 - /boot/loader/loader.conf
timeout 1
default arch
 - /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options zfs=zmypool/enc/root/default rw
 - umount /mnt/boot
 - zpool export zroot
 - reboot

10. After the first boot

 - zgenhostid $(hostid)
 - zfs create -o mountpoint=/home/ole/music -o zmypool/enc/co/music
 - zfs create -o mountpoint=/home/ole/code_lz zmypool/enc/co/code_lz
 - zpool set cachefile=/etc/zfs/zpool.cache zmypool
 - mkinitcpio -p linux
 - /boot/loader/loader.conf
editor no

11. Setup Multiple Boot Environments

 - zfs snapshot zmypool/enc/root/default@one
 - zfs snapshot zmypool/enc/root/default@two
 - zfs snapshot zmypool/enc/root/default@three

 - zfs clone zmypool/enc/root/default@one zmypool/enc/root/one
 - zfs clone zmypool/enc/root/default@two zmypool/enc/root/two
 - zfs clone zmypool/enc/root/default@three zmypool/enc/root/three

 - zfs set canmount=noauto zmypool/enc/root/one
 - zfs set canmount=noauto zmypool/enc/root/two
 - zfs set canmount=noauto zmypool/enc/root/three

 - zfs set mountpoint=/ zmypool/enc/root/one
 - zfs set mountpoint=/ zmypool/enc/root/two
 - zfs set mountpoint=/ zmypool/enc/root/three

 - zfs set compression=lz4 zmypool/enc/root/one
 - zfs set compression=lz4 zmypool/enc/root/two
 - zfs set compression=lz4 zmypool/enc/root/three

 - cp /boot/vmlinuz-linux /boot/vmlinuz-linux-one
 - cp /boot/vmlinuz-linux /boot/vmlinuz-linux-two
 - cp /boot/vmlinuz-linux /boot/vmlinuz-linux-three

 - cp /boot/initramfs-linux.img /boot/initramfs-linux-one.img
 - cp /boot/initramfs-linux.img /boot/initramfs-linux-two.img
 - cp /boot/initramfs-linux.img /boot/initramfs-linux-three.img

 - /boot/loader/entries/barch.conf
title   Arch Linux (Latest Snapshot)
linux   /vmlinuz-linux-one
initrd  /intel-ucode.img
initrd  /initramfs-linux-one.img
options zfs=zmypool/enc/root/one rw
 - /boot/loader/entries/carch.conf
title   Arch Linux (Second Snapshot)
linux   /vmlinuz-linux-two
initrd  /intel-ucode.img
initrd  /initramfs-linux-two.img
options zfs=zmypool/enc/root/two rw
 - /boot/loader/entries/darch.conf
title   Arch Linux (Third Snapshot)
linux   /vmlinuz-linux-three
initrd  /intel-ucode.img
initrd  /initramfs-linux-three.img
options zfs=zmypool/enc/root/three rw

 - /usr/local/bin/zyay
#!/bin/bash
ZRPOOL=zmypool

# cycle initramfs
sudo rm /boot/initramfs-linux-three.img
sudo mv /boot/initramfs-linux-two.img /boot/initramfs-linux-three.img
sudo mv /boot/initramfs-linux-one.img /boot/initramfs-linux-two.img
sudo cp /boot/initramfs-linux.img /boot/initramfs-linux-one.img

# cycle kernel
sudo rm /boot/vmlinuz-linux-three
sudo mv /boot/vmlinuz-linux-two /boot/vmlinuz-linux-three
sudo mv /boot/vmlinuz-linux-one /boot/vmlinuz-linux-two
sudo cp /boot/vmlinuz-linux /boot/vmlinuz-linux-one

# cycle snaps and clones
sudo zfs destroy -R ${ZRPOOL}/enc/root/default@three
sudo zfs rename ${ZRPOOL}/enc/root/default@two ${ZRPOOL}/enc/root/default@three
sudo zfs rename ${ZRPOOL}/enc/root/two ${ZRPOOL}/enc/root/three
sudo zfs rename ${ZRPOOL}/enc/root/default@one ${ZRPOOL}/enc/root/default@two
sudo zfs rename ${ZRPOOL}/enc/root/one ${ZRPOOL}/enc/root/two

# create new snap one
sudo zfs snapshot ${ZRPOOL}/enc/root/default@one
sudo zfs clone ${ZRPOOL}/enc/root/default@one ${ZRPOOL}/enc/root/one
sudo zfs set canmount=noauto ${ZRPOOL}/enc/root/one
sudo zfs set mountpoint=/ ${ZRPOOL}/enc/root/one
sudo zfs set compression=lz4 ${ZRPOOL}/enc/root/one

# update the system
sudo reflector --country France --country Germany --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
yay

# report
sudo mkdir -p /var/log/upgrade
sudo zfs snapshot ${ZRPOOL}/root/default@upgrade
sudo zfs diff ${ZRPOOL}/root/default@one ${ZRPOOL}/root/default@upgrade | sudo tee "/var/log/upgrade/$(date +"%Y_%m_%d_%H_%M")_yay_diff.log" > /dev/null
sudo zfs destroy ${ZRPOOL}/root/default@upgrade

# scrub
sudo zpool scrub ${ZRPOOL}
