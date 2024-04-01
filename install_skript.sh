#! /bin/bash

echo "Hallo, hier kommt der Linux install skript0r!"

echo "user mit su - && usermod -aG sudo USERNAME in die sudoers datei hinzufügen"

#gib dem User sudo berechtigung
#su -
#usermod -aG sudo $user
#root ausloggen
#logout root

sudo apt update -y
sudo apt upgrade -y

sudo apt install -y openscad docker python3-full python3-venv tmux ripgrep gcc make wget htop fzf vim curl git zsh fonts-hack-ttf
flatpak install -y --noninteractive flathub 

#why so serious?
sudo apt install -y neofetch cowsay fortune cmatrix vlc
sudo curl -L https://raw.githubusercontent.com/will8211/unimatrix/master/unimatrix.py -o /usr/local/bin/unimatrix
sudo chmod a+rx /usr/local/bin/unimatrix

#NAS Einrichtung
sudo apt install -y cifs-utils nfs-common


#epoptes für Schulp
sudo apt install -y epoptes-client
#epoptes Einrichtung kommt hier noch



#flathub als repository hinzufügen
sudo apt install -y flatpak plasma-discover-backend-flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

#flatpak's installieren

flatpak install -y --noninteractive flathub org.kicad.KiCad
flatpak install -y --noninteractive flathub org.inkscape.Inkscape
#flatpak install -y --noninteractive flathub com.obsproject.Studio
flatpak install -y --noninteractive flathub com.vscodium.codium
flatpak install -y --noninteractive flathub io.github.shiftey.Desktop
flatpak install -y --noninteractive flathub com.logseq.Logseq
flatpak install -y --noninteractive flathub org.freecadweb.FreeCAD
flatpak install -y --noninteractive flathub com.github.IsmaelMartinez.teams_for_linux
flatpak install -y --noninteractive flathub org.raspberrypi.rpi-imager
flatpak install -y --noninteractive flathub org.fritzing.Fritzing
flatpak install -y --noninteractive flathub com.visualstudio.code

#Kicost
sudo pipx install kicost # Install KiCost from PyPI.

#udev.rules für Platformio
curl -fsSL https://raw.githubusercontent.com/platformio/platformio-core/develop/platformio/assets/system/99-platformio-udev.rules | sudo tee /etc/udev/rules.d/99-platformio-udev.rules
sudo service udev restart
sudo udevadm control --reload-rules
sudo udevadm trigger
sudo usermod -a -G dialout $USER
sudo usermod -a -G plugdev $USER

#ohmyzsh als Shell addon
sudo chsh -s $(which zsh) $(whoami)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
echo "./zshrc sollte noch bearbeitet werden"

#install nvim
sudo apt remove -y neovim
sudo apt install -y ninja-build gettext cmake unzip curl
git clone https://github.com/neovim/neovim
cd neovim
make CMAKE_BUILD_TYPE=RelWithDebInfo
ls
cd build
cpack -G DEB
# sudo dpkg -i nvim-linux64.deb
# sudo apt remove neovim
sudo dpkg -i --force-overwrite nvim-linux64.deb

#NvChad als skin für neovim
git clone https://github.com/NvChad/starter ~/.config/nvim && nvim
