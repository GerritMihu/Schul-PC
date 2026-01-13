#!/bin/bash
# Debian Schul-PC Installationsskript
# Dieses Skript richtet einen Debian-PC für den Unterricht in Elektronik und IT ein.
# Es installiert alle nötigen Tools, Entwicklungsumgebungen und Konfigurationen.
# Debian Schul-PC Installationsskript
# Autor: Gerrit Mitterhuemer
# Version: 1.
# Datum: $(date +%Y-%m-%d)



set -e # Beendet das Skript sofort, wenn ein Fehler auftritt
set -u # Beendet das Skript, wenn eine Variable nicht definiert ist

set -euo pipefail

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color


# Funktion für grüne Log-Ausgaben mit Zeitstempel
log() {
  echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# Funktion für rote Fehlermeldungen
error() {
  echo -e "${RED}[ERROR] $1${NC}" >&2
}

# Funktion für gelbe Warnungen
warning() {
  echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Sicherheitsprüfung: Skript darf NICHT als root ausgeführt werden
if [[ $EUID -eq 0 ]]; then
  error "Dieses Script sollte nicht als root ausgeführt werden!"
  exit 1
fi

# Prüfen, ob der Benutzer sudo-Rechte hat (wichtig für alle Installationen)
if ! sudo -n true 2>/dev/null; then
  error "User hat keine sudo-Berechtigung. Bitte erst sudo-Berechtigung einrichten:"
  echo "su - && usermod -aG sudo $USER"
  exit 1
fi


# Timeshift Snapshot vor der Installation
# Timeshift ist ein Backup-Tool, das den aktuellen Systemzustand speichert.
# So kann man bei Problemen später einfach zurückrollen.

log "Erstelle Timeshift Snapshot vor der Installation"

# Falls Timeshift noch nicht installiert ist, wird es jetzt installiert
if ! command -v timeshift &> /dev/null; then
  sudo apt install -y timeshift
fi

# Snapshot mit aktuellem Datum/Uhrzeit benennen
# SNAPSHOT_NAME="pre-install-$(date +%Y%m%d_%H%M)"
# sudo timeshift --create --comments "$SNAPSHOT_NAME" --tags D
# log "Snapshot $SNAPSHOT_NAME erstellt"


log "Debian Schul-PC Installationsskript gestartet"

# 🗂️ Backup der Paketquellenliste
# Die Datei /etc/apt/sources.list enthält die Quellen für Softwarepakete.
# Wir sichern sie, bevor wir Änderungen vornehmen.
log "Erstelle Backup der sources.list"
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%Y%m%d)

# ➕ Debian Backports hinzufügen
# Backports enthalten neuere Softwareversionen für stabile Debian-Versionen.
log "Füge Debian Backports hinzu"
if ! grep -q "backports" /etc/apt/sources.list; then
  sudo sed -i '/^deb.*main$/a deb http://deb.debian.org/debian trixie-backports main' /etc/apt/sources.list
  log "Backports hinzugefügt"
else
  log "Backports bereits vorhanden"
fi

# 🔄 System aktualisieren
# Wir holen die neuesten Paketinformationen und installieren Updates.
log "Aktualisiere Paketlisten und System"
sudo apt update -y
sudo apt upgrade -y



# 🧱 Installation von Basis-Paketen
# Diese Pakete sind grundlegend für viele weitere Installationen und Funktionen.
log "Installiere Basis-Pakete"
sudo apt install -y apt-transport-https ca-certificates gnupg lsb-release curl wget git

# 🖥️ KDE Desktop Environment
# KDE ist eine grafische Benutzeroberfläche mit vielen Tools – ideal für Schul-PCs.
log "Installiere KDE Desktop Environment"
sudo apt install -y kde-full

# 🛠️ Entwicklungstools
# Diese Tools werden für das Kompilieren, Programmieren und Entwickeln benötigt.
log "Installiere Entwicklungstools"
sudo apt install -y build-essential cmake ninja-build gcc make git vim thonny python3-venv python3-pip
# pipx installieren
log "Installiere pipx"
sudo apt install -y pipx
pipx ensurepath

# Systemtools
log "Installiere Systemtools"
sudo apt install -y tmux htop btop ssh ufw ripgrep fd-find fzf zsh kitty flameshot fonts-hack-ttf minicom screen picocom timeshift gtkterm filelight libreoffice  libreoffice-l10n-en-gb  mc


# Container und Virtualisierung
log "Installiere Docker"
sudo apt install -y docker.io
sudo usermod -aG docker $USER

# NAS-Tools
log "Installiere NAS-Tools"
sudo apt install -y cifs-utils nfs-common samba syncthing
sudo usermod -aG sambashare $USER


# Netzwerktechnik
log "Installiere Netzwerktechnik-Tools"
sudo apt install -y zenmap wireshark

# Fun-Pakete
log "Installiere Fun-Pakete"
sudo apt install -y \
    fastfetch \
    cowsay \
    fortune \
    cmatrix \
    vlc \
    audacity \
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
sudo apt install -y plank conky-all rofi

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

# EDA (Electronic Design Automation) Tools
log "Installiere EDA Tools"
sudo apt install -y \
    veroroute \
    rfdump \
    gtkwave \
    iverilog \
    verilator \
    yosys \
    ghdl \
    ngspice \
    gnucap \
    octave \
    octave-signal \
    octave-control \
    scilab \

# Kicad
log "Installiere Kicad"
sudo apt install -y kicad kicad-demos  kicad-footprints  kicad-libraries  kicad-symbols  kicad-templates kicad-packages3d



# Simulation und Analyse Tools
log "Installiere Simulation Tools"
sudo apt install -y \
    sigrok-cli \
    pulseview \
    sigrok \
    openocd \
    avrdude \
    dfu-util \
    stlink-tools

# Hardware-Debugging Tools
log "Installiere Hardware-Debugging Tools"
sudo apt install -y \
    gdb-multiarch \
    binutils-arm-none-eabi \
    gcc-arm-none-eabi \
    libnewlib-arm-none-eabi \
    libstdc++-arm-none-eabi-newlib

# Programmier-Tools für verschiedene MCUs
log "Installiere MCU Programming Tools"
sudo apt install -y \
    avrdude \
    dfu-programmer \
    gputils \
    sdcc \


# FPGA/HDL Tools
log "Installiere FPGA/HDL Tools"
sudo apt install -y \
    iverilog \
    verilator \
    gtkwave \
    yosys \
    arachne-pnr \
    nextpnr-ice40 \

# Messgeräte-Software
log "Installiere Messgeräte-Software"
sudo apt install -y \
    sigrok-cli \
    pulseview \
    xoscope

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


ARCH_DEB=""
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) ARCH_DEB="amd64" ;;
  aarch64|arm64) ARCH_DEB="arm64" ;;
  *) echo "Nicht unterstützte Architektur: $ARCH"; exit 1 ;;
esac

#if [ "$(id -u)" -ne 0 ]; then
#  echo "Bitte als root ausführen (sudo bash install_sunshine_trixie.sh)."
#  exit 1
#fi

echo "[1/5] apt aktualisieren …"
sudo apt update -y
sudo apt install -y wget ca-certificates

# KDE-spezifische Pakete für Audio/Video
sudo apt install -y pipewire wireplumber libva2 libva-drm2 libva-x11-2 mesa-va-drivers \
               xdg-utils || true

DEB_NAME="sunshine-debian-trixie-${ARCH_DEB}.deb"
DL_URL="https://github.com/LizardByte/Sunshine/releases/latest/download/${DEB_NAME}"

echo "[2/5] Lade Sunshine …"
wget -O "/tmp/${DEB_NAME}" "${DL_URL}"

echo "[3/5] Installiere Sunshine …"
sudo apt install -y "/tmp/${DEB_NAME}" || (apt -f install -y && apt install -y "/tmp/${DEB_NAME}")
# Pfad definieren
SERVICE_PATH="/etc/systemd/system/sunshine.service"

echo "[4/5] Autostart konfigurieren …"

# Überprüfen, ob der Dienst bereits existiert, falls nicht: Erstellen
if ! systemctl list-unit-files | grep -q "^sunshine.service"; then
sudo bash -c "cat > ${SERVICE_PATH}" << EOF
[Unit]
Description=Sunshine - Moonlight GameStream Host
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/sunshine
Restart=on-failure
RestartSec=5s
# Optional: Falls Sunshine als spezifischer User laufen soll (empfohlen)
# User=DEIN_BENUTZERNAME

[Install]
WantedBy=multi-user.target
EOF

sudo chmod 644 ${SERVICE_PATH}
sudo systemctl daemon-reload
fi

# Dienst aktivieren und sofort starten
sudo systemctl enable sunshine.service
sudo systemctl start sunshine.service

echo "[5/5] Fertig!"




# Flatpak Setup
log "Installiere Flatpak und Flathub"
sudo apt install -y flatpak plasma-discover-backend-flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Flatpak-Anwendungen installieren
log "Installiere Flatpak-Anwendungen"
FLATPAK_APPS=(
    "org.inkscape.Inkscape"
    "com.obsproject.Studio"
    "io.github.shiftey.Desktop"
    "com.logseq.Logseq"
    "org.freecad.FreeCAD"
    "com.github.IsmaelMartinez.teams_for_linux"
    "org.raspberrypi.rpi-imager"
    "org.fritzing.Fritzing"
    "io.podman_desktop.PodmanDesktop"
    "com.microsoft.Edge"
)

for app in "${FLATPAK_APPS[@]}"; do
    log "Installiere $app"
    flatpak install -y --noninteractive flathub "$app" || warning "Installation von $app fehlgeschlagen"
done

# VSCODE install
# Install dependencies
sudo apt install -y curl apt-transport-https gpg

# Create directory if it doesn't exist
sudo mkdir -p /usr/share/keyrings

curl -s https://packages.microsoft.com/keys/microsoft.asc \
  | gpg --dearmor \
  | sudo tee /usr/share/keyrings/microsoft-archive-keyring.gpg > /dev/null

# VSCode repository
echo "deb [signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/vscode stable main" \
  | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

# Update package list
sudo apt update

# Install VSCode
sudo apt install -y code

# Wait for code command to be available
sleep 3

# Install extensions with error handling
extensions=(
    "ms-python.python"
    "ms-vscode.cpptools"
    "platformio.platformio-ide"
    "donjayamanne.python-extension-pack"
    "raspberry-pi.raspberry-pi-pico"
    "kingwampy.raspberrypi-sync"
    "ms-azuretools.vscode-docker"
    "docker.docker"
    "ryu1kn.text-marker"
    "ms-vscode-remote.remote-containers"
    "esbenp.prettier-vscode"
    "dbaeumer.vscode-eslint"
    "editorconfig.editorconfig"
    "unthrottled.doki-theme"
)

for extension in "${extensions[@]}"; do
    echo "Installing extension: $extension"
    code --force --install-extension "$extension" || echo "Failed to install: $extension"
done

echo "VSCode installation completed!"


# Arduino CLI Setup für ESP32, ATMEGA, ATTiny, RP2040
log "Konfiguriere Arduino CLI für alle MCU-Plattformen"
if command -v arduino-cli &> /dev/null; then
    # Arduino CLI Konfiguration initialisieren
    arduino-cli config init

    # Board Manager URLs hinzufügen
    arduino-cli config add board_manager.additional_urls https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
    arduino-cli config add board_manager.additional_urls https://github.com/earlephilhower/arduino-pico/releases/download/global/package_rp2040_index.json
    arduino-cli config add board_manager.additional_urls http://drazzy.com/package_drazzy.com_index.json

    # Core-Pakete aktualisieren
    arduino-cli core update-index

    # Arduino AVR Boards (ATmega328P, ATmega2560, etc.)
    arduino-cli core install arduino:avr

    # ESP32 Boards
    arduino-cli core install esp32:esp32

    # Raspberry Pi Pico/RP2040 Boards
    arduino-cli core install rp2040:rp2040

    # ATTinyCore für ATTiny Mikrocontroller
    arduino-cli core install ATTinyCore:avr

    # MegaCore für ATmega Mikrocontroller (erweiterte Unterstützung)
    arduino-cli core install MegaCore:avr

    # MiniCore für ATmega48/88/168/328 serie
    arduino-cli core install MiniCore:avr
    arduino-cli core install megaTinyCore:avr
    arduino-cli core install megaTinyCore:megaavr

    log "Arduino CLI Boards konfiguriert:"
    arduino-cli board listall | grep -E "(esp32|avr|rp2040)"
fi

# OpenOCD für Hardware-Debugging
log "Konfiguriere OpenOCD"
sudo usermod -a -G plugdev $USER
sudo usermod -a -G dialout $USER

# Rechte für raspberrypi imager
sudo usermod -a -G disk $USER

# USB-Regeln für verschiedene Programmer/Debugger
log "Installiere USB-Regeln für Hardware-Tools"

# ST-Link Regeln (für STM32, aber auch für andere ARM MCUs)
echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="3748", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="374b", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="374d", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="374e", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="374f", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="3752", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="3753", MODE="0666"' | sudo tee /etc/udev/rules.d/49-stlinkv2.rules

# J-Link Regeln
echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="1366", MODE="0666"' | sudo tee /etc/udev/rules.d/99-jlink.rules

# Black Magic Probe
echo 'SUBSYSTEM=="tty", ATTRS{interface}=="Black Magic GDB Server", SYMLINK+="ttyBmpGdb"
SUBSYSTEM=="tty", ATTRS{interface}=="Black Magic UART Port", SYMLINK+="ttyBmpTarg"' | sudo tee /etc/udev/rules.d/99-blackmagic.rules

# ESP32 Development Boards (CP2102, CH340, FTDI)
echo '# ESP32 Development Boards
SUBSYSTEM=="usb", ATTR{idVendor}=="10c4", ATTR{idProduct}=="ea60", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="7523", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="0403", ATTR{idProduct}=="6001", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="0403", ATTR{idProduct}=="6010", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="0403", ATTR{idProduct}=="6011", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="0403", ATTR{idProduct}=="6014", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="0403", ATTR{idProduct}=="6015", MODE="0666"' | sudo tee /etc/udev/rules.d/99-esp32.rules

# Arduino und AVR ISP Programmer
echo '# Arduino Boards
SUBSYSTEM=="usb", ATTR{idVendor}=="2341", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="2a03", MODE="0666"
# AVR ISP mkII
SUBSYSTEM=="usb", ATTR{idVendor}=="03eb", ATTR{idProduct}=="2104", MODE="0666"
# AVR Dragon
SUBSYSTEM=="usb", ATTR{idVendor}=="03eb", ATTR{idProduct}=="2107", MODE="0666"
# AVRISP mkII
SUBSYSTEM=="usb", ATTR{idVendor}=="03eb", ATTR{idProduct}=="2104", MODE="0666"
# USBtinyISP
SUBSYSTEM=="usb", ATTR{idVendor}=="1781", ATTR{idProduct}=="0c9f", MODE="0666"
# USBasp
SUBSYSTEM=="usb", ATTR{idVendor}=="16c0", ATTR{idProduct}=="05dc", MODE="0666"' | sudo tee /etc/udev/rules.d/99-avr.rules

# Raspberry Pi Pico (RP2040) - Picoprobe und normale Pico
echo '# Raspberry Pi Pico / RP2040
SUBSYSTEM=="usb", ATTR{idVendor}=="2e8a", ATTR{idProduct}=="0003", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="2e8a", ATTR{idProduct}=="0004", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="2e8a", ATTR{idProduct}=="000a", MODE="0666"
# Picoprobe
SUBSYSTEM=="usb", ATTR{idVendor}=="2e8a", ATTR{idProduct}=="0004", MODE="0666"' | sudo tee /etc/udev/rules.d/99-rp2040.rules

sudo udevadm control --reload-rules
sudo udevadm trigger

# Python Tools für Embedded Development (MCU-spezifisch)
log "Installiere Python Tools für MCU Development"
pipx install esptool              # ESP32/ESP8266
pipx install adafruit-ampy        # MicroPython file management
pipx install mpremote             # MicroPython REPL
pipx install thonny               # Python IDE für MicroPython
pipx install platformio          # Universal embedded development platform

# Pico SDK Setup für RP2040
log "Installiere Pico SDK für RP2040"
if [[ ! -d ~/pico ]]; then
    mkdir -p ~/pico
    cd ~/pico

    # Pico SDK klonen
    git clone -b master https://github.com/raspberrypi/pico-sdk.git
    cd pico-sdk
    git submodule update --init

    # Pico Examples klonen
    cd ~/pico
    git clone -b master https://github.com/raspberrypi/pico-examples.git

    # Pico Extras klonen
    git clone -b master https://github.com/raspberrypi/pico-extras.git

    # Picotool klonen und bauen
    git clone https://github.com/raspberrypi/picotool.git
    cd picotool
    mkdir build
    cd build
    cmake ..
    make -j4
    sudo make install

    # Umgebungsvariablen für Pico SDK setzen
    if ! grep -q "PICO_SDK_PATH" ~/.bashrc; then
        echo "export PICO_SDK_PATH=~/pico/pico-sdk" >> ~/.bashrc
        source ~/.bashrc
    fi
    if ! grep -q "PICO_SDK_PATH" ~/.zshrc 2>/dev/null; then
        echo "export PICO_SDK_PATH=~/pico/pico-sdk" >> ~/.zshrc || true
        source ~/.zshrc
    fi

    cd ~
fi

# AVR-GCC Toolchain für ATmega/ATtiny
log "Installiere AVR-GCC Toolchain"
sudo apt install -y \
    gcc-avr \
    avr-libc \
    avrdude \
    avarice \
    gdb-avr

# Zusätzliche AVR Tools
sudo apt install -y \
    uisp \
    avra \

# MPLAB X IDE Alternative (falls gewünscht)
log "Bereite MPLAB X Alternative vor"
echo "# Für MPLAB X IDE (Microchip): Download von microchip.com erforderlich"
echo "# Alternative: Verwende VS Code mit entsprechenden Extensions"

# Logic Analyzer Software
log "Installiere Logic Analyzer Software"
# PulseView ist bereits über sigrok installiert
# Zusätzlich: DSView für DreamSourceLab Logic Analyzer
if [[ ! -f /usr/local/bin/DSView ]]; then
    echo "DSView kann manuell von https://www.dreamsourcelab.com heruntergeladen werden"
fi
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
    sudo apt install -y ninja-build gettext cmake unzip curl neovim ctags vim-scripts
fi

# NvChad für Neovim
log "Installiere NvChad"
if [[ ! -d ~/.config/nvim ]]; then
    git clone https://github.com/NvChad/starter ~/.config/nvim
fi



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
echo "6. Hardware-Debugging: Verbinde ST-Link/J-Link und teste mit 'openocd'"
echo "7. Logic Analyzer: Starte PulseView für Sigrok-kompatible Geräte"
echo "8. Arduino CLI: Verwende 'arduino-cli board list' zum Testen"
echo "9. Für FPGA: Installiere Lattice iCE40 Tools oder Xilinx Vivado separat"
echo "10. KiCad und FreeCAD sind über Flatpak installiert"
echo "11. ESP32: Teste mit 'esptool.py --port /dev/ttyUSB0 flash_id'"
echo "12. RP2040: Pico SDK in ~/pico installiert, PICO_SDK_PATH gesetzt"
echo "13. ATmega/ATtiny: AVR-GCC Toolchain installiert"
echo "14. PlatformIO: Verwende 'pio device list' für verfügbare Geräte"
echo
echo "Nützliche Kommandos:"
echo "==================="
echo
echo "ESP32 Development:"
echo "- esptool.py --port /dev/ttyUSB0 flash_id"
echo "- esptool.py --port /dev/ttyUSB0 --baud 460800 write_flash 0x1000 firmware.bin"
echo "- arduino-cli compile --fqbn esp32:esp32:esp32dev MyESP32Project"
echo "- pio run -e esp32dev && pio run -e esp32dev -t upload"
echo
echo "ATMEGA Development:"
echo "- arduino-cli compile --fqbn arduino:avr:uno MyArduinoSketch"
echo "- avrdude -c arduino -p atmega328p -P /dev/ttyUSB0 -U flash:w:firmware.hex"
echo "- avr-gcc -mmcu=atmega328p -o main.elf main.c && avr-objcopy -O ihex main.elf main.hex"
echo
echo "ATTiny Development:"
echo "- arduino-cli compile --fqbn ATTinyCore:avr:attinyx5:chip=85,clock=1internal MyTinyProject"
echo "- avrdude -c usbtiny -p attiny85 -U flash:w:firmware.hex"
echo "- avr-gcc -mmcu=attiny85 -o tiny.elf tiny.c"
echo
echo "RP2040/Pico Development:"
echo "- cd ~/pico/pico-examples/blink && mkdir build && cd build"
echo "- cmake .. && make"
echo "- picotool load -f blink.uf2"
echo "- arduino-cli compile --fqbn rp2040:rp2040:rpipico MyPicoProject"
echo
echo "Allgemeine Tools:"
echo "- openocd -f interface/stlink.cfg -f target/stm32f4x.cfg"
echo "- sigrok-cli --driver fx2lafw --samples 1000 --output-format csv"
echo "- platformio device list"
echo "- minicom -D /dev/ttyUSB0 -b 115200"
echo
echo "Hardware-Debugging:"
echo "- openocd -f interface/picoprobe.cfg -f target/rp2040.cfg"
echo "- gdb-multiarch firmware.elf"
echo "- avarice --edbg --capture --jtag /dev/ttyUSB0 :4242"
echo
echo "Backup der ursprünglichen sources.list: /etc/apt/sources.list.backup.$(date +%Y%m%d)"
