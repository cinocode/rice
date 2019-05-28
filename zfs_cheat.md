1. Partition

 - efi boot part size: 300mb + (25mb x number_of_bootable_snapshots)
 - $ parted /dev/sda
 - (parted) mklabel gpt
 - (parted) mkpart ESP fat32 1MiB 400MiB
 - (parted) set 1 boot on
 - (parted) mkpart primary ext2 400MiB 99%
 - (parted) align-check optimal 1
 - 1 aligned
 - (parted) align-check optimal 2
 - 2 aligned

2. Filesystem and Encryption

 - mkfs.fat -F32 /dev/sda1
 - cryptsetup luksFormat /dev/sda2
 - cryptsetup luksOpen /dev/sda2 cryptroot

3. Partition Encrypted Container and Create Swap

 - (parted) mklabel gpt
 - (parted) mkpart ext2 0% 32GiB
 - (parted) mkpart ext2 32GiB 100%
 - mkswap /dev/mapper/cryptroot1
 - swapon /dev/mapper/cryptroot1

4. Create the Pool

 - Check sector size: 
   - parted /dev/sda
   - (parted) print
   - Model: ATA VBOX HARDDISK (scsi)
   - Disk /dev/sda: 10.7GB
   - Sector size (logical/physical): 512B/512B <--- here
   - Partition Table: gpt
   - Should you have a 4k disk then add -o ashift=12 to the zpool create command.
 - (modprobe zfs)
 - touch /etc/zfs/zpool.cache
 - zpool create -o cachefile=/etc/zfs/zpool.cache -o autotrim=on -O acltype=posixacl -m none -R /mnt zmypool /dev/mapper/cryptroot2

5. Create the Datasets

 - zfs create -o mountpoint=none zmypool/root
 - zfs create -o mountpoint=/ -o canmount=noauto -o zmypool/root/default
 - zfs create -o mountpoint=/home -o zmypool/home
 - zfs create -o mountpoint=/home/code_lz -o compression=lz4 zmypool/code_lz
 - zfs create -o mountpoint=/var/cache/pacman/pkg -o compression=lz4 zmypool/pkg
 - zfs create -o mountpoint=/var/log -o compression=lz4 zmypool/log

6. Mount everything

 - zpool export zmypool
 - zpool import -R /mnt zmypool
 - blkid /dev/sda1
 - mkdir /mnt/boot
 - mount /dev/disk/by-uuid/UUID_OF_DISK /mnt/boot

7. Install Arch

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

8. Enable Zfs on Fresh System

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

9. Setup Parted Hook for Swap

 - pacman -S parted
 - Create /etc/initcpio/install/load_part:
# /etc/initcpio/install/load_part:
#---------------------------------
#!/bin/bash
build() {
    add_binary 'partprobe'

    add_runscript
}

help() {
    cat <<HELPEOF
Probes mapped LUKS container for partitions.
HELPEOF
}
 - Create /etc/initcpio/hooks/load_part:
# /etc/initcpio/hooks/load_part:
#------------------------------
run_hook() {
    partprobe /dev/mapper/cryptroot
}
 - Edit /etc/mkinitcpio.conf
 - HOOKS="base udev keyboard autodetect keymap modconf block encrypt load_part resume zfs filesystems"
 - mkinitcpio -p linux

10. Enable Zfs Services
 - systemctl enable zfs.target
 - systemctl enable zfs-import-cache
 - systemctl enable zfs-mount
 - systemctl enable zfs-import.target

11. Install Bootloader
 - bootctl install
 - /boot/loader/loader.conf
timeout 1
default arch
 - /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options cryptdevice=/dev/disk/by-uuid/<uuid>:cryptroot zfs=zmypool/root/default rw resume=UUID=<swap UUID>
 - umount /mnt/boot
 - zpool export zroot
 - reboot

12. After the first boot

 - zpool set cachefile=/etc/zfs/zpool.cache zmypool
 - zgenhostid $(hostid)
 - mkinitcpio -p linux
 - later on create non compressed code dir
 - zfs create -o mountpoint=/home/ole/code zmypool/code
 - /boot/loader/loader.conf
editor no

13. Setup Multiple Boot Environments

 - zfs snapshot zmypool/root/default@one
 - zfs snapshot zmypool/root/default@two
 - zfs snapshot zmypool/root/default@three

 - zfs clone zmypool/root/default@one zmypool/root/one
 - zfs clone zmypool/root/default@two zmypool/root/two
 - zfs clone zmypool/root/default@three zmypool/root/three

 - zfs set canmount=noauto zmypool/root/one
 - zfs set canmount=noauto zmypool/root/two
 - zfs set canmount=noauto zmypool/root/three

 - zfs set mountpoint=/ zmypool/root/one
 - zfs set mountpoint=/ zmypool/root/two
 - zfs set mountpoint=/ zmypool/root/three

 - zfs set compression=lz4 zmypool/root/one
 - zfs set compression=lz4 zmypool/root/two
 - zfs set compression=lz4 zmypool/root/three

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
options cryptdevice=/dev/disk/by-uuid/<uuid>:cryptroot zfs=zmypool/root/one rw resume=UUID=<swap UUID>
 - /boot/loader/entries/carch.conf
title   Arch Linux (Second Snapshot)
linux   /vmlinuz-linux-two
initrd  /intel-ucode.img
initrd  /initramfs-linux-two.img
options cryptdevice=/dev/disk/by-uuid/<uuid>:cryptroot zfs=zmypool/root/two rw resume=UUID=<swap UUID>
 - /boot/loader/entries/darch.conf
title   Arch Linux (Third Snapshot)
linux   /vmlinuz-linux-three
initrd  /intel-ucode.img
initrd  /initramfs-linux-three.img
options cryptdevice=/dev/disk/by-uuid/<uuid>:cryptroot zfs=zmypool/root/three rw resume=UUID=<swap UUID>

 - /usr/local/bin/zyay
#!/bin/bash
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
sudo zfs destroy -R zmypool/root/default@three
sudo zfs rename zmypool/root/default@two zmypool/root/default@three
sudo zfs rename zmypool/root/two zmypool/root/three
sudo zfs rename zmypool/root/default@one zmypool/root/default@two
sudo zfs rename zmypool/root/one zmypool/root/two

# create new snap one
sudo zfs snapshot zmypool/root/default@one
sudo zfs clone zmypool/root/default@one zmypool/root/one
sudo zfs set canmount=noauto zmypool/root/one
sudo zfs set mountpoint=/ zmypool/root/one
sudo zfs set compression=lz4 zmypool/root/one

# update the system
sudo reflector --country France --country Germany --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
yay

# report
sudo mkdir -p /var/log/upgrade
sudo zfs snapshot zmypool/root/default@upgrade
sudo zfs diff zmypool/root/default@one zmypool/root/default@upgrade | sudo tee "/var/log/upgrade/$(date +"%Y_%m_%d_%H_%M")_yay_diff.log" > /dev/null
sudo zfs destroy zmypool/root/default@upgrade

# scrub
sudo zpool scrub zmypool
