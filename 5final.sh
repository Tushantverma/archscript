#!/usr/bin/env bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/config.sh

logo
echo -ne "

-------------------------------------------------------------------------
                    Setup hostname and timezone
-------------------------------------------------------------------------
"
echo "$NAME_OF_MACHINE" > /etc/hostname
ln -s /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc 
# Set keymaps
echo KEYMAP=$KEYMAP > /etc/vconsole.conf
loadkeys $KEYMAP
echo "LANG=${LANGLOCAL}" > /etc/locale.conf

echo -ne "

-------------------------------------------------------------------------
        Updating full system and Setting up octopi and Aur Helper
-------------------------------------------------------------------------
"

    if [ "$CHAOCHOICE" = "yes" ]; then

#adding chaotic-Aur and Black Arch Repo
pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com
pacman-key --lsign-key FBA220DFC880C036
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm
cat /root/archscript/mirror.txt >> /etc/pacman.conf
pacman -Sy --noconfirm
fi

    if [ "$BLACKCHOICE" = "yes" ]; then

    curl -O https://blackarch.org/strap.sh
    chmod +x strap.sh
    bash strap.sh
    rm /strap.sh
    pacman -Syyu --noconfirm
    fi


if [ "$AURCHOICE" = "yay" ]; then
      pacman -S yay --noconfirm
      
      elif [ "$AURCHOICE" = "paru" ]; then
      pacman -S paru --noconfirm
      
      elif [ "$AURCHOICE" = "octopi-paru" ]; then
      pacman -S paru octopi --noconfirm
      
      elif [ "$AURCHOICE" = "octopi-yay" ]; then
      pacman -S yay octopi --noconfirm
fi



#Changing The timeline auto-snap
sed -i 's|QGROUP=""|QGROUP="1/0"|' /etc/snapper/configs/root
sed -i 's|NUMBER_LIMIT="50"|NUMBER_LIMIT="5-15"|' /etc/snapper/configs/root
sed -i 's|NUMBER_LIMIT_IMPORTANT="50"|NUMBER_LIMIT_IMPORTANT="5-10"|' /etc/snapper/configs/root
sed -i 's|TIMELINE_LIMIT_HOURLY="10"|TIMELINE_LIMIT_HOURLY="2"|' /etc/snapper/configs/root
sed -i 's|TIMELINE_LIMIT_DAILY="10"|TIMELINE_LIMIT_DAILY="2"|' /etc/snapper/configs/root
sed -i 's|TIMELINE_LIMIT_WEEKLY="0"|TIMELINE_LIMIT_WEEKLY="2"|' /etc/snapper/configs/root
sed -i 's|TIMELINE_LIMIT_MONTHLY="10"|TIMELINE_LIMIT_MONTHLY="0"|' /etc/snapper/configs/root
sed -i 's|TIMELINE_LIMIT_YEARLY="10"|TIMELINE_LIMIT_YEARLY="0"|' /etc/snapper/configs/root


#activating the auto-cleanup
SCRUB=$(systemd-escape --template btrfs-scrub@.timer --path /dev/disk/by-uuid/${ROOTUUID})
systemctl enable ${SCRUB}
systemctl enable snapper-timeline.timer
systemctl enable snapper-cleanup.timer




##--------------------------------------------------------------------------------------------------##

echo "##########################################################################"
echo "######################## getting arco key and repo #######################"
echo "##########################################################################"

pacman -S --noconfirm git
git clone --depth 1 https://github.com/arcolinux/arcolinux-spices.git
./arcolinux-spices/usr/share/arcolinux-spices/scripts/get-the-keys-and-repos.sh
pacman -Syyy
rm -rf arcolinux-spices
# source :- https://www.arcolinux.info/arcolinux-spices-application/




echo "##########################################################################"
echo "###################### install all needed packages #######################"
echo "##########################################################################"

pkgs=(

############### Display pkg ################
xorg-server
xorg-apps
xorg-xinit
mesa
intel-ucode
# xf86-video-intel ## not installing this pkg because its changing display name, giving error for other pkg (eg. vibrent-linux)

grub
grub-btrfs
efibootmgr
networkmanager
network-manager-applet
os-prober
bash-completion

gparted
dosfstools    # required by gparted
mtools        # required by gparted

bat
htop
neofetch
sublime-text-4
yay
thunar
gvfs
gvfs-afc
thunar-volman
tumbler
ffmpegthumbnailer
thunar-archive-plugin
thunar-media-tags-plugin
pavucontrol
mpv
pulseaudio
pulseaudio-alsa
ntfs-3g
feh
xfce4-terminal
sxhkd
rofi
ttf-iosevka-nerd
ttf-indic-otf
polkit-gnome
man-db
fzf
xclip
chezmoi
tree
tldr
light
alsa-utils
net-tools
wireless_tools
file-roller
yt-dlp
meld
catfish

#### themes ####
lxappearance
qt5ct
a-candy-beauty-icon-theme-git
sweet-cursor-theme-git
sweet-gtk-theme-dark
xcursor-breeze
arc-blackest-theme-git

# linux-headers-lts
# linux-lts
# dialogs
# reflector

)

pacman -S --noconfirm --needed "${pkgs[@]}"







echo "##########################################################################"
echo "####################### searching for virtualization #####################"
echo "##########################################################################"

hypervisor=$(systemd-detect-virt)
    case $hypervisor in
        none )      echo "main machine is detected"
                    pacman --noconfirm -S picom 
                    ;;
        kvm )       echo "KVM has been detected, setting up guest tools."
                    #pacstrap /mnt qemu-guest-agent &>/dev/null
                    #systemctl enable qemu-guest-agent --root=/mnt &>/dev/null
                    ;;
        vmware  )   echo "VMWare Workstation/ESXi has been detected, setting up guest tools."
                    #pacstrap /mnt open-vm-tools >/dev/null
                    #systemctl enable vmtoolsd --root=/mnt &>/dev/null
                    #systemctl enable vmware-vmblock-fuse --root=/mnt &>/dev/null
                    ;;
        oracle )    echo "VirtualBox has been detected, setting up guest tools."
                    pacman --noconfirm -S virtualbox-guest-utils 
                    systemctl enable vboxservice.service
                    ;;
        microsoft ) echo "Hyper-V has been detected, setting up guest tools."
                    #pacstrap /mnt hyperv &>/dev/null
                    #systemctl enable hv_fcopy_daemon --root=/mnt &>/dev/null
                    #systemctl enable hv_kvp_daemon --root=/mnt &>/dev/null
                    #systemctl enable hv_vss_daemon --root=/mnt &>/dev/null
                    ;;
    esac





echo "##########################################################################"
echo "########################## setting up my config ##########################"
echo "##########################################################################"


echo "Enter Your Username : "
read username

su - $username -c "chezmoi init --apply https://github.com/tushantverma/dotfiles"
./home/$username/.myscripts/1_setup_all.sh





