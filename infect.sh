#!/bin/bash
systemctl start dhcpcd
systemctl enable dhcpcd
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
sleep 1
timedatectl set-ntp true
sleep 1

read -p "Username: " username
home_dir="/home/$username"
read -p "Set up a user? (y/n): " opt_user
read -p "Set up yay (y/n): " opt_yay
read -p "Install sway and a bunch of other stuff? (y/n): " opt_install
read -p "Set up dotfiles? (y/n): " opt_dot

if [ "$opt_user" = "y" ]
then
  echo "Setting up $username - please provide your password"
  useradd -m "$username"
  usermod -g users -aG wheel,video "$username"
  passwd "$username"

  echo "%wheel      ALL=(ALL) ALL" >> /etc/sudoers
  echo "%wheel      ALL=(root) NOPASSWD: /home/ole/.bin/mount_nas" >> /etc/sudoers
  echo "Defaults !tty_tickets" >> /etc/sudoers
  echo "Defaults env_reset, timestamp_timeout=30" >> /etc/sudoers
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
  rm yay.tar.gz
  cd /
fi

if [ "$opt_install" = "y" ]
then

  pacman -Syyu

  sudo -u "$username" yay -S i3 i3blocks xorg-server xorg-xinit compton autorandr arandr
  sudo -u "$username" yay -S sway swaybg swayidle swaylock-blur-bin waybar xorg-server-xwayland 
  sudo -u "$username" yay -S sddm qt5-graphicaleffects qt5-quickcontrols gstreamer gst-liav gst-plugins-base gst-plugins-good
  sudo -u "$username" yay -S ttf-inconsolata ttf-liberation ttf-dejavu otf-font-awesome system-san-francisco-font-git ttf-vlgothic
  sudo -u "$username" yay -S zsh tmux gvim keychain openssh xdg-user-dirs rsync
  sudo -u "$username" yay -S rofi w3m feh pacman-contrib thunar ranger trash-cli
  sudo -u "$username" yay -S acpi sysstat alsa-utils ntfs-3g
  sudo -u "$username" yay -S pavucontrol pulseaudio pulseaudio-bluetooth pasystray pulseaudio-ctl
  sudo -u "$username" yay -S networkmanager networkmanager-openconnect network-manager-applet-indicator
  sudo -u "$username" yay -S mpv vlc arc-gtk-theme viewnior tumbler ffmpegthumbnailer
  sudo -u "$username" yay -S gvfs gvfs-smb xarchiver reflector redshift-wayland-git
  sudo -u "$username" yay -S git yadm maven wget nodejs npm jdk8-openjdk
  sudo -u "$username" yay -S iw dialog wpa_supplicant
  sudo -u "$username" yay -S grim slurp rxvt-unicode-pixbuf flashfocus-git
  sudo -u "$username" yay -S clipman kanshi-git wdisplays-git
  sudo -u "$username" yay -S google-chrome
  sudo -u "$username" yay -S pass tree browserpass-chrome diceware pass-extension-tail pass-git-helper

  chsh -s /bin/zsh "$username"

  echo "#!/bin/bash" > /usr/local/bin/google-chrome-stable-incognito
  echo "google-chrome-stable --incognito" >> /usr/local/bin/google-chrome-stable-incognito
  chmod +x /usr/local/bin/google-chrome-stable-incognito

  echo "DESKTOP=${home_dir}" > /etc/xdg/user-dirs.defaults
  echo 'DOWNLOAD=down' >> /etc/xdg/user-dirs.defaults
  echo 'DOCUMENTS=doc' >> /etc/xdg/user-dirs.defaults
  echo 'MUSIC=music' >> /etc/xdg/user-dirs.defaults
  echo 'PICTURES=pic' >> /etc/xdg/user-dirs.defaults
  echo 'VIDEOS=vid' >> /etc/xdg/user-dirs.defaults
  cd "$home_dir"
  sudo -u "$username" xdg-user-dirs-update
  cd /

  sudo -u "$username" git clone https://github.com/cinocode/dvorak_ger_io "$home_dir/.dvorak_ger_io"
  chown -R $username:users "$home_dir/.dvorak_ger_io"
  cd "$home_dir/.dvorak_ger_io"
  sudo -u "$username" git checkout gk64
  sh "$home_dir/.dvorak_ger_io/install_xkb.sh"
  cd /

  # setup xkb dvorak ger io symbols
  # localectl set-x11-keymap dvorak_ger_io
fi

if [ "$opt_dot" = "y" ]
then
  cd "$home_dir"
  sudo -u "$username" yadm clone https://github.com/cinocode/dotfiles
  sudo -u "$username" sh "$home_dir/.config/dots/init_vim.sh"
  sudo -u "$username" sh "$home_dir/.config/dots/init_configs.sh"
  sudo -u "$username" sh "$home_dir/.bin/install_zsh"
  sudo -u "$username" mv "$home_dir/go" "$home_dir/.config"
fi

systemctl start NetworkManager
systemctl enable NetworkManager
systemctl enable systemd-timesyncd

cp /rice/sddm/sddm.conf /etc/sddm.conf
systemctl enable sddm
git clone https://github.com/stuomas/delicious-sddm-theme.git
cd delicious-sddm-theme
./install.sh
cd ..
rm -rf delicious-sddm-theme
cat /rice/sddm/theme.conf > /usr/share/sddm/themes/delicious/theme.conf
cp /rice/sddm/sway.svg /usr/share/sddm/themes/delicious/icons/delicate/sway.svg
echo 'NoDisplay=true' >> /usr/share/xsessions/i3-with-shmlog.desktop

sudo -u "$username" mkdir "/home/${username}/code"
mv /rice "/home/${username}/code"
chown -R $username:users "/home/${username}/code/rice"

echo This is a good time to take care of graphic card drivers or microcode
echo With systemd boot you might want to run: 'yay -S systemd-boot-pacman-hook'
