#/bin/sh
get_latest_release() {
  wget -O - -o /dev/null "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
  grep '"tag_name":' |                                            # Get tag line
  sed -E 's/.*"v([^"]+)".*/\1/'                                    # Pluck JSON value
}
log(){
  printf "$BBlue$1$NC\n"
}
dlog(){
  printf "$RED$1$NC\n"
}

#config
RED='\033[0;31m'
BBlue='\033[1;34m'
NC='\033[0m' # No Color
GIT_HUB="ku-leuven-msec/Damn-Vulnerable-Device-Seminar"
TMP_PATH="/tmp/dvd"
mkdir -p $TMP_PATH
REL=$(get_latest_release $GIT_HUB)
TOOL_PATH="$TMP_PATH/Damn-Vulnerable-Device-Seminar-$REL"
SERVICE_BASE_PATH="/opt/dvd"
ALPINE_VERSION=v$(cut -d'.' -f1,2 /etc/alpine-release)

load_installation_files() {
    # Getting the files
  mkdir -p "$TMP_PATH"
  cd "$TMP_PATH"
  
  wget "https://github.com/$GIT_HUB/archive/refs/tags/v$REL.zip"
  unzip "v$REL".zip

}
full_device_setup(){
  
    
  log "Load Installation Files"
  load_installation_files
  log "Moving files to correct location"
  mv $TOOL_PATH/attacker/* /home/kali/Desktop/
  log "Changing Ettercap config"
  mv "/home/kali/Desktop/etter.conf" "/etc/ettercap/etter.conf"



  log "Cleanup"
  rm -rf "$TOOL_PATH"
  rm /home/kali/Desktop/setup_attacker.sh
  log "Installation READY"
}

full_device_setup
