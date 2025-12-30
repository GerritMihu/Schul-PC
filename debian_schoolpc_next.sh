#!/usr/bin/env bash
# Debian Schul-PC: Pflege, Sicherung, Administration & Klassenraum-Überwachung
# Autor: M365 Copilot (für Gerrit Mitterhuemer)
# Datum: $(date '+%Y-%m-%d')
# Lizenz: MIT
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
IFS=$'\n\t'
# =====================
# Konfigurationswerte
# =====================
# Passe diese Werte an deine Umgebung an:
RSYSLOG_REMOTE_HOST="logserver.example.local" # zentraler Logserver (leer lassen, um zu überspringen)
RSYSLOG_REMOTE_PROTO="tcp" # tcp oder udp
RSYSLOG_REMOTE_PORT="514"
BACKUP_REPO="/mnt/nas/borg-repo" # lokaler Mount oder ssh-Ziel z.B. user@nas:/backups/schulpc
BACKUP_PATHS=("/etc" "/home" "/usr/local" "/var/log")
BACKUP_EXCLUDES=("/var/cache" "/var/tmp" "/var/lib/apt/lists" "/home/*/.cache")
BACKUP_SCHEDULE="daily" # daily/weekly/monthly (Timer wird erstellt)
ENABLE_VEYON="true" # Veyon für Klassenraumsteuerung installieren
ENABLE_EPOPTES="false" # Epoptes optional (falls LTSP genutzt)
ENABLE_WAZUH_AGENT="false" # Wazuh-Agent (nur wenn ein Wazuh-Manager vorhanden ist)
AUDIT_WATCH_DIRS=("/home" "/mnt/klassen") # Verzeichnisse für Datei-Zugriffsüberwachung
STUDENTS_GROUP="students" # Gruppe für Schülerkonten
APT_PARALLEL_DOWNLOADS="8" # Beschleunigt apt-Downloads
UNATTENDED_AUTO_REBOOT="true" # automatischer Neustart nach Kernel/Glibc-Updates
UNATTENDED_REBOOT_TIME="02:00" # Uhrzeit für Auto-Reboot

# >>> NEU: Proxmox ISO SMB-Mount & Workshop-Schalter <<<
ISO_SERVER="192.168.129.25"
ISO_PATH="/var/lib/vz/template/iso"
ISO_MOUNT="/mnt/isos"
CREDENTIALS_FILE="/etc/samba/isos.creds"
ENABLE_WORKSHOP_LAYER="false"   # Standard: aus (auf true setzen für MCU-Stack)

# =====================
# Hilfsfunktionen
# =====================
log() { echo -e "\e[32m[$(date '+%Y-%m-%d %H:%M:%S')] $*\e[0m"; }
warn() { echo -e "\e[33m[WARN] $*\e[0m"; }
error() { echo -e "\e[31m[ERROR] $*\e[0m" 1>&2; }
need_sudo() {
  if [[ $(id -u) -ne 0 ]]; then
    if command -v sudo >/dev/null; then
      export SUDO="sudo"
    else
      error "Dieses Skript benötigt Root-Rechte. Installiere zunächst 'sudo' oder führe als root aus."; exit 1
    fi
  else
    export SUDO=""
  fi
}
get_codename() {
  if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    echo "${VERSION_CODENAME:-}" | tr -d '\n'
  fi
}
apt_update_upgrade() {
  log "Aktualisiere Paketlisten & aktualisiere System"
  $SUDO apt update
  $SUDO apt -y upgrade
}
add_backports_if_needed() {
  local codename
  codename=$(get_codename)
  if [[ -z "$codename" ]]; then warn "Konnte Debian-Codename nicht ermitteln. Überspringe Backports."; return; fi
  log "Prüfe Backports-Eintrag für $codename"
  if ! grep -q "${codename}-backports" /etc/apt/sources.list; then
    echo "deb http://deb.debian.org/debian ${codename}-backports main contrib non-free non-free-firmware" | $SUDO tee -a /etc/apt/sources.list >/dev/null
    $SUDO apt update; log "Backports hinzugefügt"
  else log "Backports bereits vorhanden"; fi
  cat <<EOF | $SUDO tee /etc/apt/preferences.d/99-backports >/dev/null
Package: *
Pin: release a=${codename}-backports
Pin-Priority: 100
EOF
}
install_base_packages() {
  log "Installiere Basis-/Admin-Pakete"
  $SUDO apt install -y ca-certificates gnupg curl wget git jq tmux htop btop ufw rsyslog vim ripgrep fzf fd-find zsh kitty mc apt-transport-https lsb-release debian-goodies
}
enable_unattended_upgrades() {
  log "Aktiviere 'unattended-upgrades' für automatische Sicherheitsupdates"
  $SUDO apt install -y unattended-upgrades apt-listchanges
  $SUDO dpkg-reconfigure -f noninteractive unattended-upgrades || true
  cat <<EOF | $SUDO tee /etc/apt/apt.conf.d/20auto-upgrades >/dev/null
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Download-Upgradeable-Packages "1";
EOF
  cat <<EOF | $SUDO tee /etc/apt/apt.conf.d/51unattended-upgrades-reboot >/dev/null
Unattended-Upgrade::Automatic-Reboot "$UNATTENDED_AUTO_REBOOT";
Unattended-Upgrade::Automatic-Reboot-Time "$UNATTENDED_REBOOT_TIME";
EOF
}
install_timeshift() {
  log "Installiere Timeshift und erstelle initialen Snapshot (rsync)"
  $SUDO apt install -y timeshift
  $SUDO timeshift --create --comments "Initial" --tags D || warn "Timeshift Snapshot konnte nicht erstellt werden (ggf. first-run GUI nötig)."
}
install_borg_and_timer() {
  log "Installiere BorgBackup & richte systemd-Backup-Job ein"
  $SUDO apt install -y borgbackup
  cat <<'EOF' | $SUDO tee /etc/systemd/system/borg-backup.service >/dev/null
[Unit]
Description=BorgBackup – tägliches Backup (verschlüsselt, deduplikation)
Wants=network-online.target
After=network-online.target
[Service]
Type=oneshot
Environment=REPO=%i
ExecStart=/usr/local/sbin/borg-run.sh "$REPO"
[Install]
WantedBy=multi-user.target
EOF
  cat <<'EOF' | $SUDO tee /etc/systemd/system/borg-backup.timer >/dev/null
[Unit]
Description=Timer für BorgBackup – täglich 02:30
[Timer]
OnCalendar=*-*-* 02:30:00
Persistent=true
[Install]
WantedBy=timers.target
EOF
  cat <<'EOF' | $SUDO tee /usr/local/sbin/borg-run.sh >/dev/null
#!/usr/bin/env bash
set -euo pipefail
REPO="$1"
HOST="$(hostname -s)"
DATE="$(date '+%Y-%m-%d')"
PATHS_FILE="/etc/borg/paths.conf"
EXCLUDES_FILE="/etc/borg/excludes.conf"
readarray -t PATHS < <(grep -v '^#' "$PATHS_FILE" 2>/dev/null || echo "/etc")
EXCLUDES_ARGS=()
if [[ -r "$EXCLUDES_FILE" ]]; then
  while read -r line; do [[ -z "$line" || "$line" =~ ^# ]] && continue; EXCLUDES_ARGS+=("--exclude" "$line"); done < "$EXCLUDES_FILE"
fi
if ! borg info "$REPO" >/dev/null 2>&1; then borg init --encryption=repokey "$REPO"; fi
borg create --stats --progress "$REPO"::"${HOST}-${DATE}" "${PATHS[@]}" "${EXCLUDES_ARGS[@]}"
borg prune -v --list "$REPO" --keep-daily=7 --keep-weekly=4 --keep-monthly=6
EOF
  $SUDO chmod +x /usr/local/sbin/borg-run.sh
  $SUDO mkdir -p /etc/borg
  printf "%s\n" "${BACKUP_PATHS[@]}" | $SUDO tee /etc/borg/paths.conf >/dev/null
  printf "%s\n" "${BACKUP_EXCLUDES[@]}" | $SUDO tee /etc/borg/excludes.conf >/dev/null
  $SUDO systemctl daemon-reload
  $SUDO systemctl enable --now borg-backup.service
  $SUDO systemctl enable --now borg-backup.timer
}
configure_rsyslog_forward() {
  [[ -z "$RSYSLOG_REMOTE_HOST" ]] && { warn "RSYSLOG_REMOTE_HOST nicht gesetzt – überspringe zentrales Logging"; return; }
  log "Konfiguriere zentrale Log-Weiterleitung zu $RSYSLOG_REMOTE_HOST:$RSYSLOG_REMOTE_PORT ($RSYSLOG_REMOTE_PROTO)"
  $SUDO apt install -y rsyslog
  cat <<EOF | $SUDO tee /etc/rsyslog.d/10-forward.conf >/dev/null
# zentrale Weiterleitung
\$ActionQueueFileName fwdQueue
\$ActionQueueMaxDiskSpace 1g
\$ActionQueueSaveOnShutdown on
\$ActionQueueType LinkedList
\$ActionResumeRetryCount -1
*.* @@${RSYSLOG_REMOTE_HOST}:${RSYSLOG_REMOTE_PORT};RSYSLOG_SyslogProtocol23Format
EOF
  $SUDO systemctl restart rsyslog
}
configure_ufw() {
  log "Konfiguriere UFW-Firewall (SSHD, Syslog, Veyon optional)"
  $SUDO apt install -y ufw
  $SUDO ufw allow OpenSSH
  [[ -n "$RSYSLOG_REMOTE_HOST" ]] && $SUDO ufw allow ${RSYSLOG_REMOTE_PORT}
  [[ "$ENABLE_VEYON" == "true" ]] && $SUDO ufw allow 11100/tcp
  $SUDO ufw --force enable || warn "UFW konnte nicht aktiviert werden (ggf. bereits aktiv)."
  $SUDO ufw status
}
install_auditd_rules() {
  log "Installiere auditd & setze Watch-Regeln"
  $SUDO apt install -y auditd audispd-plugins
  RULES_FILE="/etc/audit/rules.d/99-schulpc.rules"
  printf "%s\n" "-D" | $SUDO tee "$RULES_FILE" >/dev/null
  echo "-b 8192" | $SUDO tee -a "$RULES_FILE" >/dev/null
  for d in "${AUDIT_WATCH_DIRS[@]}"; do echo "-w $d -p rwa -k schueler-datei" | $SUDO tee -a "$RULES_FILE" >/dev/null; done
  echo "-a always,exit -F arch=b64 -S execve -k proc-exec" | $SUDO tee -a "$RULES_FILE" >/dev/null
  echo "-a always,exit -F arch=b32 -S execve -k proc-exec" | $SUDO tee -a "$RULES_FILE" >/dev/null
  $SUDO augenrules --load
  $SUDO systemctl enable --now auditd
}
install_classroom_tools() {
  if [[ "$ENABLE_VEYON" == "true" ]]; then
    log "Installiere Veyon (Klassenraum-Management)"
    $SUDO apt install -y veyon
    $SUDO systemctl enable --now veyon.service || true
  fi
  if [[ "$ENABLE_EPOPTES" == "true" ]]; then
    log "Installiere Epoptes (Client & Server)"
    $SUDO apt install -y epoptes epoptes-client || warn "Epoptes-Installation fehlgeschlagen"
  fi
}
# ---- Bestehendes Workshop-Toolset: nur noch optional aufrufbar ----
install_workshop_tools() {
  log "Installiere Entwicklungs-/Elektronik-Tools (Auszug)"
  $SUDO apt install -y build-essential cmake ninja-build gcc make git python3 python3-venv python3-pip openocd avrdude dfu-util stlink-tools gdb-multiarch picocom minicom yosys verilator iverilog gtkwave ngspice
}
install_vscode_only() {
  log "Installiere Visual Studio Code (VSCode) – VSCodium wird bewusst NICHT installiert"
  $SUDO mkdir -p /usr/share/keyrings
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | $SUDO tee /usr/share/keyrings/microsoft-archive-keyring.gpg >/dev/null
  echo "deb [signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/vscode stable main" | $SUDO tee /etc/apt/sources.list.d/vscode.list >/dev/null
  $SUDO apt update
  $SUDO apt install -y code
  local extensions=( "ms-python.python" "ms-vscode.cpptools" "platformio.platformio-ide" "ms-azuretools.vscode-docker" "ms-vscode-remote.remote-containers" "esbenp.prettier-vscode" "dbaeumer.vscode-eslint" "editorconfig.editorconfig" )
  for ext in "${extensions[@]}"; do code --force --install-extension "$ext" || true; done
}
post_cleanup() { log "Aufräumen"; $SUDO apt -y autoremove; $SUDO apt -y autoclean; }

# =====================
# >>> NEU: Addons/Plugins & SMB/Flatpak Integration <<<
# =====================
install_flatpak_orcaslicer() {
  log "Installiere Flatpak und OrcaSlicer"
  $SUDO apt update
  $SUDO apt install -y flatpak
  $SUDO flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  if [[ -f "./OrcaSlicer-Linux-flatpak_x86_64.flatpak" ]]; then
    $SUDO flatpak install -y ./OrcaSlicer-Linux-flatpak_x86_64.flatpak
  else
    warn "OrcaSlicer Flatpak-Datei nicht gefunden. Bitte manuell aus dem offiziellen Release bereitstellen."
  fi
}
configure_smb_mount() {
  log "Konfiguriere SMB-Mount für ISOs"
  $SUDO apt install -y cifs-utils
  $SUDO mkdir -p "$ISO_MOUNT"
  if [[ ! -f "$CREDENTIALS_FILE" ]]; then
    $SUDO bash -c "cat > $CREDENTIALS_FILE" <<EOF
username=DEIN_USER
password=DEIN_PASS
EOF
    $SUDO chmod 600 "$CREDENTIALS_FILE"
    warn "Bitte Zugangsdaten in $CREDENTIALS_FILE anpassen."
  fi
  # Fstab-Eintrag (Share-Name entspricht dem Basisnamen des ISO-Pfads, z. B. 'iso')
  if ! grep -q "//$ISO_SERVER" /etc/fstab; then
    echo "//$ISO_SERVER/$(basename $ISO_PATH) $ISO_MOUNT cifs credentials=$CREDENTIALS_FILE,vers=3.0,uid=$(id -u),gid=$(id -g),rw 0 0" | $SUDO tee -a /etc/fstab
  fi
  $SUDO mount -a || warn "Mount fehlgeschlagen. Prüfe Zugangsdaten & Samba-Share auf dem Server."
}
install_freecad_addons() {
  log "Installiere FreeCAD Addons (Parts-Library, SheetMetal)"
  mkdir -p "$HOME/.local/share/FreeCAD/Mod"
  cd "$HOME/.local/share/FreeCAD/Mod"
  [[ ! -d parts_library ]] && git clone --depth 1 https://github.com/FreeCAD/FreeCAD-library.git parts_library
  [[ ! -d SheetMetal ]] && git clone --depth 1 https://github.com/shaise/FreeCAD_SheetMetal.git SheetMetal
  pipx install networkx || true
}
install_kicad_plugins() {
  log "Installiere KiCad Plugins (KiKit, InteractiveHtmlBom)"
  pipx install KiKit
  pipx install InteractiveHtmlBom
}
install_prusaslicer() { log "Installiere PrusaSlicer"; $SUDO apt install -y prusa-slicer; }
install_workshop_layer() {
  log "Installiere Workshop-Layer (MCU-Stack)"
  $SUDO apt install -y openocd avrdude dfu-util stlink-tools gdb-multiarch picocom minicom
  pipx install esptool adafruit-ampy mpremote
  curl -fsSL https://raw.githubusercontent.com/platformio/platformio-core/develop/platformio/assets/system/99-platformio-udev.rules | $SUDO tee /etc/udev/rules.d/99-platformio-udev.rules
  $SUDO udevadm control --reload-rules && $SUDO udevadm trigger
  $SUDO usermod -aG dialout,plugdev "$USER"
}
show_ventoy_hint() {
  log "Ventoy Hinweis: ISO-Dateien liegen unter $ISO_MOUNT. Kopiere sie auf den Ventoy-Stick:"
  echo "cp $ISO_MOUNT/*.iso /media/$USER/Ventoy/ && sync"
}

# =====================
# Hauptablauf
# =====================
main() {
  need_sudo
  apt_update_upgrade
  add_backports_if_needed
  install_base_packages
  enable_unattended_upgrades
  install_timeshift
  install_borg_and_timer
  configure_rsyslog_forward
  configure_ufw
  install_auditd_rules
  install_classroom_tools

  # Neue Blöcke
  install_flatpak_orcaslicer
  configure_smb_mount
  install_freecad_addons
  install_kicad_plugins
  install_prusaslicer
  show_ventoy_hint

  # Workshop optional
  if [[ "$ENABLE_WORKSHOP_LAYER" == "true" ]]; then
    install_workshop_layer
    install_workshop_tools  # ggf. zusätzliche EDA-Tools
  fi

  install_vscode_only
  post_cleanup
  log "Fertig. Beachte Datenschutz-Hinweise für Monitoring in Schulumgebungen."
}
main "$@"
