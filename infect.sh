#!/bin/bash
timedatectl set-ntp true
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
systemctl start dhcpcd
systemctl enable dhcpcd

read -p "Username: " username
home_dir="/home/$username"
read -p "Set up a user? (y/n): " opt_user
read -p "Set up yay (y/n): " opt_yay
read -p "Install sway and a bunch of other stuff? (y/n): " opt_install
read -p "Set up dotfiles? (y/n): " opt_dot
read -p "Install Intel microcode? (y/n)" opt_intel
read -p "Install Amd microcode? (y/n)" opt_amd

if [ "$opt_user" = "y" ]
then
  echo "Setting up $username - please provide your password"
  useradd -m "$username"
  usermod -aG wheel "$username"
  passwd "$username"

  echo "%wheel      ALL=(ALL) ALL" >> /etc/sudoers
  echo "Defaults !tty_tickets" >> /etc/sudoers
  echo "Defaults passwd_timeout=60" >> /etc/sudoers

  echo 'if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then' >> "$home_dir/.bash_profile"
  echo '  sway' >> "$home_dir/.bash_profile"
  echo 'fi' >> "$home_dir/.bash_profile"
  chown ole:ole $home_dir/.bash_profile

  mkdir -p /etc/systemd/system/getty@tty1.service.d/
  echo [Service] > /etc/systemd/system/getty@tty1.service.d/override.conf
  echo ExecStart= >> /etc/systemd/system/getty@tty1.service.d/override.conf
  echo ExecStart=-/usr/bin/agetty --autologin $username --noclear %I $TERM >> /etc/systemd/system/getty@tty1.service.d/override.conf

  sudo -u "$username" mkdir "$home_dir/code"
  sudo -u "$username" git clone https://github.com/cinocode/dvorak_ger_io "$home_dir/code/dvorak_ger_io"
  sudo -u "$username" "$home_dir/code/dvorak_ger_io/xmodmap/Xmodmap" "$home_dir/.Xmodmap"
fi

if [ "$opt_yay" = "y" ]
then
  echo Setting up yay

  cd "$home_dir"
  curl -sO https://aur.archlinux.org/cgit/aur.git/snapshot/yay.tar.gz
  sudo -u "$username" tar -xvf yay.tar.gz
  cd yay
  sudo -u "$username" makepkg --noconfirm -si
  cd ..
  rm -rf yay
fi

if [ "$opt_install" = "y" ]
then
  pacman -Syy

  pacman -Su

  pacman -S sway swaylock ttf-inconsolata ttf-liberation ttf-font-awesome tmux gvim keychain openssh rofi feh compton acpi sysstat alsa-utils ntfs-3g pavucontrol pulseaudio pulseaudio-bluetooth networkmanager networkmanager-openconnect network-manager-applet vlc thunar ranger gtk-chtheme arc-gtk-theme viewnior tumbler ffmpegthumbnailer gvfs gvfs-smb xarchiver redshift arandr autorandr

  cd /
  git clone https://github.com/cinocode/st.git
  cd /st
  make install
  cd /
  rm -rf /st

  sudo -u "$username" yay -Sy google-chrome enpass-bin system-san-francisco-font-git ttf-vlgothic screengrab pasystray pulseaudio-ctl

  echo "#!/bin/bash" > /usr/local/bin/google-chrome-stable-incognito
  echo "google-chrome-stable --incognito" >> /usr/local/bin/google-chrome-stable-incognito
  chmod +x /usr/local/bin/google-chrome-stable-incognito
fi

if [ "$opt_dot" = "y" ]
then
  sudo -u "$username" git clone https://github.com/cinocode/dotfiles "$home_dir/.dotfiles"
  sudo -u "$username" sh "$home_dir/.dotfiles/init_configs.sh"
  sudo -u "$username" sh "$home_dir/.dotfiles/init_wallpaper.sh"
  sudo -u "$username" sh "$home_dir/.dotfiles/init_vim.sh"

  mkdir -p "$home_dir/.config/sway"
  cp "$home_dir/.config/i3/config" "$home_dir/.config/sway/"
fi


if [ "$opt_intel" = "y" ]
then
  pacman -S intel_ucode
  grub-mkconfig -o /boot/grub/grub.cfg
fi

if [ "$opt_amd" = "y" ]
then
  pacman -S amd_ucode
  grub-mkconfig -o /boot/grub/grub.cfg
fi

echo If everything looks clean, you probably want to rm -rf /rice
echo Also this is a good time to take care of drivers
