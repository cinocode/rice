1. Partition

 - efi boot part size: 300mb + (25mb x number_of_bootable_snapshots)
 - put the rest in partition that will contain luks
 - mkfs.fat -F32 /dev/sda1
 - cryptsetup luksFormat /dev/sda2
 - cryptsetup open /dev/sda2 cryptzfs

2. Create the Pool

 - Check sector size: 
   - parted /dev/sda
   - (parted) print
   - Model: ATA VBOX HARDDISK (scsi)
   - Disk /dev/sda: 10.7GB
   - Sector size (logical/physical): 512B/512B <--- here
   - Partition Table: gpt
   - Should you have a 4k disk then add -o ashift=12 to the zpool create command.
 - Check device id with blkid /dev/mapper/cryptzfs
 - (modprobe zfs)
 - export ZRPOOL=zmypool
 - touch /etc/zfs/${ZRPOOL}.cache
 - zpool create -o cachefile=/etc/zfs/${ZRPOOL}.cache -o autotrim=on -O acltype=posixacl -m none -R /mnt ${ZRPOOL} /dev/mapper/cryptzfs

3. Create the Datasets

 - zfs create -o mountpoint=none -o compression=lz4 ${ZRPOOL}/co
 - zfs create -o mountpoint=none ${ZRPOOL}/root
 - zfs create -o mountpoint=/ ${ZRPOOL}/root/default
 - zfs create -o mountpoint=/home ${ZRPOOL}/home
 - zfs create -o mountpoint=/var/cache/pacman/pkg ${ZRPOOL}/co/pkg
 - zfs create -o mountpoint=/var/log -o com.sun:auto-snapshot=false ${ZRPOOL}/co/log

 - zfs create -V 4G -b $(getconf PAGESIZE) -o compression=zle -o logbias=throughput -o sync=always -o primarycache=metadata -o secondarycache=none -o com.sun:auto-snapshot=false ${ZRPOOL}/swap
 - mkswap -f /dev/zvol/${ZRPOOL}/swap
 - echo /dev/zvol/${ZRPOOL}/swap none swap discard 0 0 >> /etc/fstab

4. Mount everything

 - zpool export ${ZRPOOL}
 - zpool import -R /mnt ${ZRPOOL}
 - blkid /dev/sda1
 - mkdir /mnt/boot
 - mount /dev/disk/by-uuid/UUID_OF_DISK /mnt/boot

5. Install Arch

 - Optimize mirror list
 - pacstrap -i /mnt base base-devel git sudo vim
 - genfstab -U -p /mnt | grep boot >> /mnt/etc/fstab
 - delete zfs entries from /mnt/etc/fstab
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
 - zpool set cachefile=/etc/zfs/zpool.cache ${ZRPOOL}
 - check zpool cache for contents to be sure

7. Setup Mkinitcpio

 - Edit /etc/mkinitcpio.conf
 - HOOKS="base udev keyboard autodetect keymap modconf block encrypt zfs filesystems"
 - mkinitcpio -p linux

8. Enable Zfs Services
 - zfs set canmount=noauto ${ZRPOOL}/root/default
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
options cryptdevice=/dev/disk/by-uuid/<uuid>:cryptroot zfs=zmypool/root/default rw
 - umount /mnt/boot
 - zpool export zroot
 - reboot

10. After the first boot

 - zgenhostid $(hostid)
 - zfs create -o mountpoint=/home/ole/music -o ${ZRPOOL}/co/music
 - zfs create -o mountpoint=/home/ole/code_lz ${ZRPOOL}/co/code_lz
 - zpool set cachefile=/etc/zfs/zpool.cache ${ZRPOOL}
 - mkinitcpio -p linux
 - /boot/loader/loader.conf
editor no

11. Setup Multiple Boot Environments

 - zfs snapshot ${ZRPOOL}/root/default@one
 - zfs snapshot ${ZRPOOL}/root/default@two
 - zfs snapshot ${ZRPOOL}/root/default@three

 - zfs clone ${ZRPOOL}/root/default@one ${ZRPOOL}/root/one
 - zfs clone ${ZRPOOL}/root/default@two ${ZRPOOL}/root/two
 - zfs clone ${ZRPOOL}/root/default@three ${ZRPOOL}/root/three

 - zfs set canmount=noauto ${ZRPOOL}/root/one
 - zfs set canmount=noauto ${ZRPOOL}/root/two
 - zfs set canmount=noauto ${ZRPOOL}/root/three

 - zfs set mountpoint=/ ${ZRPOOL}/root/one
 - zfs set mountpoint=/ ${ZRPOOL}/root/two
 - zfs set mountpoint=/ ${ZRPOOL}/root/three

 - zfs set compression=lz4 ${ZRPOOL}/root/one
 - zfs set compression=lz4 ${ZRPOOL}/root/two
 - zfs set compression=lz4 ${ZRPOOL}/root/three

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
options cryptdevice=/dev/disk/by-uuid/<uuid>:cryptroot zfs=zmypool/root/one rw
 - /boot/loader/entries/carch.conf
title   Arch Linux (Prior Snapshot)
linux   /vmlinuz-linux-two
initrd  /intel-ucode.img
initrd  /initramfs-linux-two.img
options cryptdevice=/dev/disk/by-uuid/<uuid>:cryptroot zfs=zmypool/root/two rw
 - /boot/loader/entries/darch.conf
title   Arch Linux (Oldest Snapshot)
linux   /vmlinuz-linux-three
initrd  /intel-ucode.img
initrd  /initramfs-linux-three.img
options cryptdevice=/dev/disk/by-uuid/<uuid>:cryptroot zfs=zmypool/root/three rw

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
sudo zfs destroy -R ${ZRPOOL}/root/default@three
sudo zfs rename ${ZRPOOL}/root/default@two ${ZRPOOL}/root/default@three
sudo zfs rename ${ZRPOOL}/root/two ${ZRPOOL}/root/three
sudo zfs rename ${ZRPOOL}/root/default@one ${ZRPOOL}/root/default@two
sudo zfs rename ${ZRPOOL}/root/one ${ZRPOOL}/root/two

# create new snap one
sudo zfs snapshot ${ZRPOOL}/root/default@one
sudo zfs clone ${ZRPOOL}/root/default@one ${ZRPOOL}/root/one
sudo zfs set canmount=noauto ${ZRPOOL}/root/one
sudo zfs set mountpoint=/ ${ZRPOOL}/root/one
sudo zfs set compression=lz4 ${ZRPOOL}/root/one

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
