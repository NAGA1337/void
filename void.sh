#!/bin/bash

# Name: Void Linux Installer
# Authors: Marcílio Nascimento <marcilio.mcn at gmail.com>
# First Release: 2019, March
# Description: Alternative LEAN install script that replaces the standard Void Linux installer.
# License: MIT
# Version: 202002.02

# Exit immediately if a command exits with a non-zero exit status
set -e

clear
echo '######################################'
echo '######## Void Linux Installer ########'
echo '######################################'
echo ''

# Declaring LV array (for LVM)
# declare -A LV

##############################
######## HEADER START ########
##############################
# DECLARE CONSTANTS AND VARIABLES
UEFI=0 # 1=UEFI, 0=Legacy/BIOS platform along the script
# REPO="http://alpha.us.repo.voidlinux.org"
REPO='http://alpha.de.repo.voidlinux.org'
# VGNAME="vgpool"
# CRYPTSETUP_OPTS=""
# UPDATETYPE='-Sy' # If GenuineIntel update local repository and change the next one to only '-y'
# SWAP=1 # 1=On, 0=Off

# PARTITIONS SIZE (M for Megabytes, G for Gigabytes)
EFISIZE='1G'
SWAPSIZE='10G'
# BOOTSIZE='512M' # 512MB for /boot should be sufficient to host 7 to 8 kernel versions
ROOTSIZE='10G'

# LVM Size ARRAY (testing)
# LV[root]="2G"
# LV[var]="2G" - Test if necessary for desktop
# LV[home]="1G"

# SETTINGS
USERNAME='wompsi' # Set your username
HOSTNAME='voidi' # Pick your favorite name
HARDWARECLOCK='UTC' # Set RTC (Real Time Clock) to UTC or localtime
TIMEZONE='Europe/Helsinki' # Set which region on Earth the user is
KEYMAP='fi' # Define keyboard layout: us or br-abnt2 (include more options)
FONT='Lat2-Terminus16' # Set type face for terminal before X server starts
TTYS=2 # Amount of ttys which should be setup
# LANG='en_US.UTF-8' # I guess this one only necessary in glibc installs
PKG_LIST='base-system git grub' # Install this packages (add more to your taste)
# Tip: In this step, python3 is a dependency from ufw...no need to install this otherwise
############################
######## HEADER END ########
############################

# Set installation font (more legible)
setfont $FONT

# Option to select the device type/name
echo ''
echo 'DEVICE SELECTION'
echo ''
echo ''
PS3='Select your device type/name: '
options=('sda' 'sdb' 'nvme')
select opt in "${options[@]}"
do
  case $opt in
    'sda')
      DEVNAME='/dev/sda'
      break
      ;;
    'sdb')
      DEVNAME='/dev/sdb'
      break
      ;;
    'nvme')
      DEVNAME='/dev/nvme'
      break
      ;;
    *)
      echo 'This option is invalid.'
      ;;
  esac
done
clear

# Option to select the file system type to format paritions
echo ''
echo 'FILE SYSTEM TYPE SELECTION'
echo ''
echo ''
PS3='Select the file system type to format partitions: '
filesystems=('btrfs' 'ext4' 'xfs')
select filesysformat in "${filesystems[@]}"
do
  case $filesysformat in
    'btrfs')
      FSYS='btrfs'
      break
      ;;
    'ext4')
      FSYS='ext4'
      break
      ;;
    'xfs')
      FSYS='xfs'
      break
      ;;
    *)
      echo 'This option is invalid.'
      ;;
  esac
done
clear
# Wipe /dev/${DEVNAME} (return this and test when the installation process is working)
#dd if=/dev/zero of=/dev/${DEVNAME} bs=1M count=100

# Detect if we're in UEFI or legacy mode installation
[ -d /sys/firmware/efi ] && UEFI=1

###### PARTITIONS - START ######
# Device Paritioning for UEFI/GPT or BIOS/MBR
# if [ $UEFI ]; then
#   sfdisk $DEVNAME <<-EOF
#     label: gpt
#     ,$EFISIZE,U,*
#     ,$SWAPSIZE,S
#     ,$BOOTSIZE,L
#     ,$ROOTSIZE,L
#     ,,L
#   EOF
# else
#   sfdisk $DEVNAME <<-EOF
#     label: dos
#     ,$SWAPSIZE,S
#     ,$BOOTSIZE,L,*
#     ,,L
#   EOF
# fi

sfdisk $DEVNAME <<EOF
  label: gpt
  ,${EFISIZE},U,*
  ,${SWAPSIZE},S
  ,${ROOTSIZE},L
  ,,L
EOF
###### PARTITIONS - END ######

# FORMATING
mkfs.vfat -F 32 -n EFI ${DEVNAME}1
mkswap -L swp0 ${DEVNAME}2
mkfs.$FSYS -L voidlinux ${DEVNAME}3
mkfs.$FSYS -L home ${DEVNAME}4

# MOUNTING
mount ${DEVNAME}3 /mnt
mkdir /mnt/boot && mount ${DEVNAME}1 /mnt/boot
mkdir /mnt/home && mount ${DEVNAME}4 /mnt/home

# When UEFI
mkdir /mnt/boot/efi && mount ${DEVNAME}1 /mnt/boot/efi

###### LVM AND CRYPTOGRAPHY - START ######

# # Options for encrypt partitions process
# if [ $UEFI ]; then
#   BOOTPART="3"
#   ROOTPART="4"
# else
#   BOOTPART="2"
#   ROOTPART="3"
# fi

# # Start PKG_LIST variable and increase packages by the process installation
# PKG_LIST="lvm2 cryptsetup"

# # Install requirements for LVM and Cryptography
# xbps-install -Syf $PKG_LIST

# echo "Encrypt - boot partition"
# cryptsetup ${CRYPTSETUP_OPTS} luksFormat -c aes-xts-plain64 -s 512 /dev/${DEVNAME}${BOOTPART}

# echo "Open - boot partition"
# cryptsetup luksOpen /dev/${DEVNAME}${BOOTPART} crypt-boot

# echo "Encrypt - root partition"
# cryptsetup ${CRYPTSETUP_OPTS} luksFormat -c aes-xts-plain64 -s 512 /dev/${DEVNAME}${ROOTPART}

# echo "Open - root partition"
# cryptsetup luksOpen /dev/${DEVNAME}${ROOTPART} crypt-pool

# # Create VolumeGroup
# pvcreate /dev/mapper/crypt-pool
# vgcreate ${VGNAME} /dev/mapper/crypt-pool
# for FS in ${!LV[@]}; do
#   lvcreate -L ${LV[$FS]} -n ${FS/\//_} ${VGNAME}
# done

# # If exist SWAP, create LV drive
# [ $SWAP -eq 1 ] && lvcreate -L ${SWAPSIZE} -n swap ${VGNAME}
# #if [ $SWAP -eq 1 ]; then
# #  lvcreate -L ${SWAPSIZE} -n swap ${VGNAME}
# #fi

# # Format filesystems
# [ $UEFI ] && mkfs.vfat /dev/${DEVNAME}1
# #if [ $UEFI ]; then
# #  mkfs.vfat /dev/${DEVNAME}1
# #fi

# mkfs.ext4 -L boot /dev/mapper/crypt-boot

# for FS in ${!LV[@]}; do
#   mkfs.ext4 -L ${FS/\//_} /dev/mapper/${VGNAME}-${FS/\//_}
# done

# if [ $SWAP -eq 1 ]; then
#   mkswap -L swap /dev/mapper/${VGNAME}-swap
# fi


# # Mount them
# mount /dev/mapper/${VGNAME}-root /mnt

# for dir in dev proc sys boot; do
#   mkdir /mnt/${dir}
# done

# ## Remove root and sort keys
# unset LV[root]

# for FS in $(for key in "${!LV[@]}"; do printf '%s\n' "$key"; done| sort); do
#   mkdir -p /mnt/${FS}
#   mount /dev/mapper/${VGNAME}-${FS/\//_} /mnt/${FS}
# done

# if [ $UEFI ]; then
#   mount /dev/mapper/crypt-boot /mnt/boot
#   mkdir /mnt/boot/efi
#   mount /dev/${DEVNAME}1 /mnt/boot/efi
# else
#   mount /dev/mapper/crypt-boot /mnt/boot
# fi

# for fs in dev proc sys; do
#   mount -o bind /${fs} /mnt/${fs}
# done

# # ?????????
# mkdir -p /mnt/var/db/xbps/keys/
# cp -a /var/db/xbps/keys/* /mnt/var/db/xbps/keys/

###### LVM AND CRYPTOGRAPHY - END ######

###### PREPARING VOID LINUX INSTALLING PACKAGES ######
# If UEFI installation, add GRUB specific package
[ $UEFI ] && PKG_LIST+='-x86_64-efi'

# Install Void Linux
clear
echo ''
echo 'Installing Void Linux files'
echo ''
env XBPS_ARCH=x86_64-musl xbps-install -Sy -R ${REPO}/current/musl -r /mnt $PKG_LIST

# Upon completion of the install, we set up our chroot jail, and chroot into our mounted filesystem:
mount -t proc proc /mnt/proc
mount -t sysfs sys /mnt/sys
mount -o bind /dev /mnt/dev
mount -t devpts pts /mnt/dev/pts

# Copy DNS file - DO NOT WORKING
# cp -L /etc/resolv.conf /mnt/etc/
# For notebooks: added DNSs below in /etc/resolv.conf (because the notbook do not always is on the same router) 
# printf 'nameserver 8.8.8.8\nnameserver 8.8.4.4' > /mnt/etc/resolv.conf

######################
### CHROOTed START ###
######################
clear
echo ''
echo 'Set Root Password'
echo ''
# create the password for the root user
while true; do
  chroot /mnt passwd root && break
  echo 'Password did not match. Please try again'
  sleep 3s
  echo ''
done

clear
echo ''
echo 'Adjust/Correct Root Permissions'
chroot /mnt chown root:root /
chroot /mnt chmod 755 /

clear
echo ''
echo 'Customizations'
echo $HOSTNAME > /mnt/etc/hostname

cat >> /mnt/etc/rc.conf <<EOF
HARDWARECLOCK="${HARDWARECLOCK}"
TIMEZONE="${TIMEZONE}"
KEYMAP="${KEYMAP}"
FONT="${FONT}"
TTYS=2
EOF

##################################################
#### GLIBC ONLY - START - USE GLIBC IMAGE ISO ####
##################################################

# modify /etc/default/libc-locales and uncomment:
#en_US.UTF-8 UTF-8

# Or whatever locale you want to use. And run:
#xbps-reconfigure -f glibc-locales

# OLD CONFIGS
# echo "LANG=$LANG" > /mnt/etc/locale.conf
# echo "$LANG $(echo ${LANG} | cut -f 2 -d .)" >> /mnt/etc/default/libc-locales
# chroot /mnt xbps-reconfigure -f glibc-locales
# OLD CONFIGS

##########################
#### GLIBC ONLY - END ####
##########################

clear
echo ''
echo 'Generating /etc/fstab'
###############################
#### FSTAB ENTRIES - START ####
###############################
# For reference: <file system> <dir> <type> <options> <dump> <pass>
cat > /mnt/etc/fstab <<EOF
tmpfs /tmp  tmpfs defaults,nosuid,nodev 0 0
$(blkid ${DEVNAME}1 | cut -d ' ' -f 4 | tr -d '"') /boot vfat  rw,fmask=0133,dmask=0022,noatime,discard  0 2
$(blkid ${DEVNAME}2 | cut -d ' ' -f 3 | tr -d '"') swap  swap  commit=60,barrier=0  0 0
$(blkid ${DEVNAME}3 | cut -d ' ' -f 3 | tr -d '"') / $FSYS rw,noatime,discard,commit=60,barrier=0 0 1
$(blkid ${DEVNAME}4 | cut -d ' ' -f 3 | tr -d '"') /home $FSYS rw,discard,commit=60,barrier=0 0 2
EOF

# For a removable drive I include the line:
# LABEL=volume  /media/blahblah xfs rw,relatime,nofail 0 0
# The important setting here is ***nofail***.
#############################
#### FSTAB ENTRIES - END ####
#############################

# echo "LABEL=root  /       ext4    rw,relatime,data=ordered,discard    0 0" > /mnt/etc/fstab
# echo "LABEL=boot  /boot   ext4    rw,relatime,data=ordered,discard    0 0" >> /mnt/etc/fstab

# for FS in $(for key in "${!LV[@]}"; do printf '%s\n' "$key"; done| sort); do
#   echo "LABEL=${FS/\//_}  /${FS}	ext4    rw,relatime,data=ordered,discard    0 0" >> /mnt/etc/fstab
# done

# echo "tmpfs       /tmp    tmpfs   size=1G,noexec,nodev,nosuid     0 0" >> /mnt/etc/fstab

# Write on FSTAB if is an UEFI installation
# [ $UEFI ] && echo "/dev/${DEVNAME}1   /boot/efi   vfat    defaults    0 0" >> /mnt/etc/fstab
#if [ $UEFI ]; then
#  echo "/dev/${DEVNAME}1   /boot/efi   vfat    defaults    0 0" >> /mnt/etc/fstab
#fi

# Write on FSTAB if SWAP partition exist
# [ $SWAP -eq 1 ] && echo "LABEL=swap  none       swap     defaults    0 0" >> /mnt/etc/fstab
#if [ $SWAP -eq 1 ]; then
#  echo "LABEL=swap  none       swap     defaults    0 0" >> /mnt/etc/fstab
#fi

# Install GRUB
# cat << EOF >> /mnt/etc/default/grub
# GRUB_TERMINAL_INPUT="console"
# GRUB_TERMINAL_OUTPUT="console"
# GRUB_ENABLE_CRYPTODISK=y
# EOF
# sed -i 's/GRUB_BACKGROUND.*/#&/' /mnt/etc/default/grub
# chroot /mnt grub-install /dev/${DEVNAME}

# LUKS_BOOT_UUID="$(lsblk -o NAME,UUID | grep ${DEVNAME}${BOOTPART} | awk '{print $2}')"
# LUKS_DATA_UUID="$(lsblk -o NAME,UUID | grep ${DEVNAME}${ROOTPART} | awk '{print $2}')"
# echo "GRUB_CMDLINE_LINUX=\"rd.vconsole.keymap=${KEYMAP} rd.lvm=1 rd.luks=1 rd.luks.allow-discards rd.luks.uuid=${LUKS_BOOT_UUID} rd.luks.uuid=${LUKS_DATA_UUID}\"" >> /mnt/etc/default/grub

clear
echo ''
echo 'Install GRUB'
echo ''
# Install GRUB to the disk
chroot /mnt grub-install $DEVNAME

# clear
# echo "Configurar GRUB"
# # Generate the configuration file
# chroot /mnt grub-mkconfig -o /mnt/boot/grub/grub.cfg

clear
echo ''
echo 'Read the newest kernel'
# Cat the last Linux Kernel Version
KERNEL_VER=$(chroot /mnt xbps-query -s 'linux[0-9]*' | cut -f 2 -d ' ' | cut -f 1 -d -)

clear
echo ''
echo 'Reconfigure initramfs'
echo ''
# Setup the kernel hooks (ignore grup complaints about sdc or similar)
chroot /mnt xbps-reconfigure -f $KERNEL_VER

### SETUP SYSTEM INFOS START ###
clear
echo '######## Setup System Infos ########'
echo ''
echo '1. Activate DHCP deamon to enable network connection'
echo '2. Activate SSH deamon to enable SSH server'
echo '3. Remove all gettys except for tty1 and tty2'
echo '4. Create user, set password and add sudo permissions'
echo '5. Update mirror and sync main repo (best for Brazil)'
echo '6. Permanent swappiness optimization (great for Linux Desktops)'
echo '7. Correct the grub install'
echo ''
cat > /mnt/tmp/bootstrap.sh <<EOCHROOT
ln -s /etc/sv/dhcpcd /etc/runit/runsvdir/default/
ln -s /etc/sv/sshd /etc/runit/runsvdir/default/
rm /etc/runit/runsvdir/default/agetty-tty[3456]

useradd -g users -G wheel,storage,audio $USERNAME
echo ''
echo 'Define password for user ${USERNAME}'
echo ''

while true; do
  passwd $USERNAME && break
  echo 'Password did not match. Please try again'
  sleep 3s
  echo ''
done

echo '%wheel ALL=(ALL) ALL, NOPASSWD: /usr/bin/halt, /usr/bin/poweroff, /usr/bin/reboot, /usr/bin/shutdown, /usr/bin/zzz, /usr/bin/ZZZ, /usr/bin/mount, /usr/bin/umount' > /etc/sudoers.d/99_wheel

echo 'repository=${REPO}/current/musl' > /etc/xbps.d/00-repository-main.conf
xbps-install -Su

mkdir /etc/sysctl.d/
echo 'vm.swappiness=10' > /etc/sysctl.d/99-swappiness.conf

update-grub
EOCHROOT

chroot /mnt /bin/sh /tmp/bootstrap.sh
### SETUP SYSTEM INFOS END ###

# VVV confirm if necessary for glibc
# grub-mkconfig > /boot/grub/grub.cfg
# grub-install $DEV

# Bugfix for EFI installations (after finished, poweroff e poweron, the system do not start)
[ $UEFI ] && install -D /mnt/boot/efi/EFI/void/grubx64.efi /mnt/boot/efi/EFI/BOOT/bootx64.efi

# Umount folder used for instllation
umount -R /mnt

clear
echo ''
echo '####################################################'
echo '######## Void Linux Installed Successfully! ########'
echo '####################################################'

poweroff