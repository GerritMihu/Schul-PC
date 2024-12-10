#!/bin/bash

#
# Das ist das config script für Arch Linux
#

# 
# Allgemeine cli programme
#

sudo pacman -Syu --noconfirm --needed git base-devel wget curl go fd-find popper-utils fd-find popper-utils 7zip zoxide kitty flameshot tmux ripgrep gcc make


# Install YAY package manager
git clone https://aur.archlinux.org/yay.git
sudo chown -R $USER:users yay
cd yay
makepkg -si
cd
yay --version

rm -frd yay
#löscht ordner mit allen seinen Inhalten und fragt nicht mehr nach


yay -S --noconfirm ml4w-hyprland ml4w-hyprland-setup
yay -S --noconfirm oh-my-posh


# system programme

sudo pacman -S --noconfirm --needed docker podman flatpak


#nas freigaben
sudo pacman -S --noconfirm --needed gvfs gvfs-smb


yay -S ventoy-bin --noconfirm

# allgemeine Programme
sudo pacman -S --noconfirm --needed firefox krita libreoffice obs-studio inkscape openscad
flatpak install -y logseq


# cad, electronic 
sudo pacman -S --noconfirm --needed kicad freecad
# if you want to install the official libraries (recommended):
sudo pacman -Syu --asdeps kicad-library kicad-library-3d
# --asdeps installiert die packete als dependensies das bedeutet sie werden bei der deinstallation mit gelöscht
yay -S kibot --noconfirm



# programmieren, raspberry, microcontrollers...


sudo pacman -S --noconfirm --needed arduino code rpi-imager podmandesktop

# damit die vs-code extentions auch da sind
yay -S --noconfirm code-marketplace


#gnome keyring für error in Github-desktop-bin davor installieren
sudo pacman -S --noconfirm --needed gnome-keyring

yay -S --noconfirm github-desktop-bin


#nicht wichtiges
sudo pacman -S --noconfirm --needed cowsay fortune-mod cmatrix vlc lolcat 
yay -S --noconfirm wttr cbonsai


#hyprland config anpassen
# Tastaturlayout auf de


#hyprbar
