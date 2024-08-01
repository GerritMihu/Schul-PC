#! /bin/bash

echo "Hallo, hier kommt der Linux install skript!"

echo "user mit su - && usermod -aG sudo USERNAME in die sudoers datei hinzufügen"

#gib dem User sudo berechtigung
#su -
#usermod -aG sudo $user
#root ausloggen
#logout root

sudo apt update -y
sudo apt upgrade -y

sudo apt install -y openscad docker.io python3-full python3-venv tmux ripgrep gcc make wget htop fzf vim curl git zsh fonts-hack-ttf

#why so serious?
sudo apt install -y neofetch cowsay fortune cmatrix vlc cbonsai lolcat cava
sudo curl -L https://raw.githubusercontent.com/will8211/unimatrix/master/unimatrix.py -o /usr/local/bin/unimatrix
sudo chmod a+rx /usr/local/bin/unimatrix


#yazi kitty usw..
sudo apt install fd-find popper-utils 7zip zoxide


#NAS Einrichtung
sudo apt install -y cifs-utils nfs-common


#epoptes für Schulpc
sudo apt install -y epoptes-client
sudo sed -i 's/#SERVER=server/SERVER=B038teac.htl-steyr.ac.at/g' /etc/default/epoptes-client
sudo epoptes-client -c
sudo epoptes-client


#flathub als repository hinzufügen
sudo apt install -y flatpak plasma-discover-backend-flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

#flatpak's installieren

flatpak install -y --noninteractive flathub org.kicad.KiCad
flatpak install -y --noninteractive flathub org.inkscape.Inkscape
flatpak install -y --noninteractive flathub com.obsproject.Studio
#flatpak install -y --noninteractive flathub com.vscodium.codium
flatpak install -y --noninteractive flathub io.github.shiftey.Desktop
flatpak install -y --noninteractive flathub com.logseq.Logseq
flatpak install -y --noninteractive flathub org.freecadweb.FreeCAD
flatpak install -y --noninteractive flathub com.github.IsmaelMartinez.teams_for_linux
flatpak install -y --noninteractive flathub org.raspberrypi.rpi-imager
flatpak install -y --noninteractive flathub org.fritzing.Fritzing
flatpak install -y --noninteractive flathub com.visualstudio.code
flatpak install -y --noninteractive flathub io.podman_desktop.PodmanDesktop


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


#powerlevel10k als default layout
sudo curl -o /usr/local/share/fonts/m/MesloLGS_NF_Regular.ttf  https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc


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



sudo docker pull ghcr.io/inti-cmnb/kicad8_auto_full:dev_1.7.1-dcc8512_k8.0.2_d_sid_b3.5.1
sudo docker run -it ghcr.io/inti-cmnb/kicad8_auto_full:dev_1.7.1-dcc8512_k8.0.2_d_sid_b3.5.1


#		- nun sind wir im container auf der cli
#		- kibot-check zum bestätigen ob alles korrekt funktioniert
#		- git pull ein Kicad-projekt
#		- cd ins projekt
#		- kibot --quick-start legt die Dateien mit der  Beispielconfig ab
#		- docker cp zum kopieren der datei in das host system
#		  =======
