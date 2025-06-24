#!/bin/bash

# Debian Schul-PC Installationsskript
# Autor: Mitterhuemer Gerrit
# Version: 1.0
# Datum: $(date 2025-06-25)

set -e  # Script bei Fehlern beenden
set -u  # Fehler bei undefinierten Variablen

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging-Funktion
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    error "Dieses Script sollte nicht als root ausgeführt werden!"
    exit 1
fi

# Check if user has sudo privileges
if ! sudo -n true 2>/dev/null; then
    error "User hat keine sudo-Berechtigung. Bitte erst sudo-Berechtigung einrichten:"
    echo "su - && usermod -aG sudo $USER"
    exit 1
fi

log "Debian Schul-PC Installationsskript gestartet"

# Backup der sources.list
log "Erstelle Backup der sources.list"
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%Y%m%d)

# Backports hinzufügen
log "Füge Debian Backports hinzu"
if ! grep -q "backports" /etc/apt/sources.list; then
    sudo sed -i '/^deb.*main$/a deb http://deb.debian.org/debian bookworm-backports main' /etc/apt/sources.list
    log "Backports hinzugefügt"
else
    log "Backports bereits vorhanden"
fi

# System Update
log "Aktualisiere Paketlisten und System"
sudo apt update -y
sudo apt upgrade -y

# Basis-Pakete installieren
log "Installiere Basis-Pakete"
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    curl \
    wget \
    git

# KDE Desktop Environment
log "Installiere KDE Desktop Environment"
sudo apt install -y kde-standard

# Entwicklungstools
log "Installiere Entwicklungstools"
sudo apt install -y \
    build-essential \
    cmake \
    ninja-build \
    gcc \
    make \
    git \
    vim \
    python3-full \
    python3-venv \
    python3-pip

# Systemtools
log "Installiere Systemtools"
sudo apt install -y \
    tmux \
    htop \
    ripgrep \
    fd-find \
    fzf \
    zsh \
    kitty \
    flameshot \
    fonts-hack-ttf

# Container und Virtualisierung
log "Installiere Docker"
sudo apt install -y docker.io
sudo usermod -aG docker $USER

# NAS-Tools
log "Installiere NAS-Tools"
sudo apt install -y cifs-utils nfs-common

# Fun-Pakete
log "Installiere Fun-Pakete"
sudo apt install -y \
    neofetch \
    cowsay \
    fortune \
    cmatrix \
    vlc \
    cbonsai \
    lolcat \
    cava

# Unimatrix installieren
log "Installiere Unimatrix"
if [[ ! -f /usr/local/bin/unimatrix ]]; then
    sudo curl -L https://raw.githubusercontent.com/will8211/unimatrix/master/unimatrix.py -o /usr/local/bin/unimatrix
    sudo chmod +x /usr/local/bin/unimatrix
fi

# Ricing-Tools
log "Installiere Ricing-Tools"
sudo apt install -y plank conky rofi

# VSCodium Repository und Installation
log "Installiere VSCodium"
if ! command -v codium &> /dev/null; then
    wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
        | gpg --dearmor \
        | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg

    echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' \
        | sudo tee /etc/apt/sources.list.d/vscodium.list

    sudo apt update && sudo apt install -y codium
fi

# ESP-IDF Setup
log "Installiere ESP-IDF Abhängigkeiten"
sudo apt install -y \
    git \
    wget \
    flex \
    bison \
    gperf \
    python3 \
    python3-pip \
    python3-venv \
    cmake \
    ninja-build \
    ccache \
    libffi-dev \
    libssl-dev \
    dfu-util \
    libusb-1.0-0

# ESP-IDF Installation
log "Installiere ESP-IDF"
if [[ ! -d ~/esp/esp-idf ]]; then
    mkdir -p ~/esp
    cd ~/esp
    git clone --recursive https://github.com/espressif/esp-idf.git
    cd ~/esp/esp-idf
    ./install.sh all

    # Füge ESP-IDF export zu .bashrc hinzu
    if ! grep -q "esp-idf/export.sh" ~/.bashrc; then
        echo "alias get_idf='. \$HOME/esp/esp-idf/export.sh'" >> ~/.bashrc
    fi
    cd ~
fi

# Epoptes Client (falls in Schulumgebung)
log "Konfiguriere Epoptes Client"
if command -v epoptes-client &> /dev/null; then
    sudo apt install -y epoptes-client
    sudo sed -i 's/#SERVER=server/SERVER=B038teac.htl-steyr.ac.at/g' /etc/default/epoptes-client
    sudo systemctl enable epoptes-client
fi

# Flatpak Setup
log "Installiere Flatpak und Flathub"
sudo apt install -y flatpak plasma-discover-backend-flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Flatpak-Anwendungen installieren
log "Installiere Flatpak-Anwendungen"
FLATPAK_APPS=(
    "org.kicad.KiCad"
    "org.inkscape.Inkscape"
    "com.obsproject.Studio"
    "io.github.shiftey.Desktop"
    "com.logseq.Logseq"
    "org.freecad.FreeCAD"
    "com.github.IsmaelMartinez.teams_for_linux"
    "org.raspberrypi.rpi-imager"
    "org.fritzing.Fritzing"
    "com.visualstudio.code"
    "io.podman_desktop.PodmanDesktop"
)

for app in "${FLATPAK_APPS[@]}"; do
    log "Installiere $app"
    flatpak install -y --noninteractive flathub "$app" || warning "Installation von $app fehlgeschlagen"
done

# PlatformIO udev rules
log "Installiere PlatformIO udev rules"
curl -fsSL https://raw.githubusercontent.com/platformio/platformio-core/develop/platformio/assets/system/99-platformio-udev.rules | sudo tee /etc/udev/rules.d/99-platformio-udev.rules
sudo udevadm control --reload-rules
sudo udevadm trigger
sudo usermod -a -G dialout $USER
sudo usermod -a -G plugdev $USER

# Zsh und Oh My Zsh
log "Installiere Oh My Zsh"
if [[ ! -d ~/.oh-my-zsh ]]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    sudo chsh -s $(which zsh) $USER
fi

# Powerlevel10k
log "Installiere Powerlevel10k"
if [[ ! -d ~/powerlevel10k ]]; then
    # MesloLGS NF Font installieren
    sudo mkdir -p /usr/local/share/fonts/
    sudo curl -o /usr/local/share/fonts/MesloLGS_NF_Regular.ttf \
        https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
    sudo fc-cache -f -v

    # Powerlevel10k klonen
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k

    # In .zshrc hinzufügen
    if ! grep -q "powerlevel10k" ~/.zshrc; then
        echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >> ~/.zshrc
    fi
fi

# Neovim von Source kompilieren
log "Installiere Neovim"
if ! command -v nvim &> /dev/null; then
    sudo apt remove -y neovim || true
    sudo apt install -y ninja-build gettext cmake unzip curl

    cd /tmp
    git clone https://github.com/neovim/neovim
    cd neovim
    make CMAKE_BUILD_TYPE=RelWithDebInfo
    cd build
    cpack -G DEB
    sudo dpkg -i --force-overwrite nvim-linux64.deb
    cd ~
fi

# NvChad für Neovim
log "Installiere NvChad"
if [[ ! -d ~/.config/nvim ]]; then
    git clone https://github.com/NvChad/starter ~/.config/nvim
fi

# pipx installieren
log "Installiere pipx"
sudo apt install -y pipx
pipx ensurepath

# esptool installieren
log "Installiere esptool"
pipx install esptool

# ESP-Drone Projekt klonen
log "Klone ESP-Drone Projekt"
if [[ ! -d ~/ESP-Drone ]]; then
    cd ~
    git clone 'https://github.com/Circuit-Digest/ESP-Drone'
fi

# Cleanup
log "Führe System-Cleanup durch"
sudo apt autoremove -y
sudo apt autoclean

log "Installation abgeschlossen!"
echo
echo "WICHTIGE HINWEISE:"
echo "=================="
echo "1. Bitte melde dich ab und wieder an, damit die Gruppenzugehörigkeiten aktiv werden"
echo "2. Für ESP-IDF: Führe 'get_idf' aus, um die Umgebung zu laden"
echo "3. Konfiguriere Powerlevel10k mit 'p10k configure'"
echo "4. Die .zshrc sollte noch nach deinen Wünschen angepasst werden"
echo "5. Docker-Gruppe ist aktiv nach dem nächsten Login"
echo
echo "Backup der ursprünglichen sources.list: /etc/apt/sources.list.backup.$(date +%Y%m%d)"
