#!/bin/sh
DEBUG_SETUP=1

log(){
  printf "$BBlue$1$NC\n"
}
dlog(){
  printf "$RED$1$NC\n"
}

set_date() {
  M=`wget -O - -o  /dev/null http://worldtimeapi.org/api/timezone/Europe/Brussels | sed -E "s|,|\n|g" | grep 'utc_datetime'| cut -d ':' -f2-`
  D=`echo $M | cut -d "T" -f1`
  T=`echo $M | cut -d "T" -f2- | cut -d "." -f1`
  date -s "${D:1} $T" 
}

#general functions:
get_latest_release() {
  wget -O - -o /dev/null "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
  grep '"tag_name":' |                                            # Get tag line
  sed -E 's/.*"v([^"]+)".*/\1/'                                    # Pluck JSON value
}

get_current_ip() {
  local ip=`ifconfig eth0 2>/dev/null|awk '/inet addr:/ {print $2}'|sed 's/addr://'`
  if [ -z "$ip" ]; then
    ip=`ifconfig eth0 2>/dev/null|awk '/inet / {print $2}'|sed 's/addr://'`
  fi
  echo $ip
}

current_ip=$(get_current_ip)

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
SERVICE_PATH="$SERVICE_BASE_PATH/services"

# ADDING USERS
add_users() {
  dlog "- Adding least privileged user: client"
  useradd -p '$6$vOsShJfzJ$nspR/.gahnFFRBL9hrTkWCwr8fCjhkIaEyABvCCpCVL6p1G3dZVEhvmbcOg2Bh1OG.a9ZmKkzwo2V5ZDOin73/' client
  mkdir /home/client

  dlog "- Adding bit more privileged user: manager"
  useradd -p '$6$dY5hO/6B48/9D.66$QHHDlmdkw.CHtzQg.W/e7s8SnGJaJgwVYwKzLu1vB6ZTeKBb2BXj1xc7wJJUl7nFgUXy6AHf/6z63yOPuXBT7/' manager
  mkdir /home/manager

  dlog "- Adding group"
  groupadd managerGroup

  dlog "- Adding manager to that group" 
  usermod -a -G managerGroup manager 

  dlog "- Adding sudo rights"
  echo 'client ALL=(root) NOPASSWD: /usr/bin/less /home/manager/*' >> /etc/sudoers

}

setup_polling() {
  dlog "- Creating polling file and adding content"
  touch /home/manager/checkNetwork.sh
  echo 'ping -c 1 google.com' > /home/manager/checkNetwork.sh

  dlog "- adding the rights for that file"
  chown :managerGroup /home/manager/checkNetwork.sh
  chmod 771 /home/manager/checkNetwork.sh

  dlog "- Adding the file to the cronjob"
  echo '* * * * * root /home/manager/checkNetwork.sh' >> /etc/crontab
}

setup_python() {
  python3 -m pip install --trusted-host pypi.python.org --trusted-host files.pythonhosted.org --trusted-host pypi.org --upgrade pip
  pip config set global.trusted-host "pypi.org pypi.python.org files.pythonhosted.org"
}


monitor_service() {
  chmod +x "$SERVICE_PATH/$1/check_daemon.sh"
  echo "*/1 * * * * $SERVICE_PATH/$1/check_daemon.sh" >> /etc/crontab
}

install_service() {
  if [ -f "$1/server.py" ]; then
    service=`basename $1`
    log "Installing $service service"
    if [ -f "$SERVICE_PATH/$service/requirements.txt" ]; then
      pip install -r "$SERVICE_PATH/$service/requirements.txt"
    fi
    monitor_service $service $usr
  fi
}

install_services() {
  mkdir -p "$SERVICE_PATH"
  
  cp -r $TOOL_PATH/services/* $SERVICE_PATH/
  chmod 751 "$SERVICE_PATH/check_daemon.sh"
  
  for d in "$SERVICE_PATH/"*
  do
      install_service "$d"
  done
}

load_installation_files() {
    # Getting the files
  mkdir "$TMP_PATH"
  cd "$TMP_PATH"
  
  wget "https://github.com/$GIT_HUB/archive/refs/tags/v$REL.zip"
  unzip "v$REL".zip

}
cleanup_installation_files(){
  rm -r $TMP_PATH
}

setup_ssh() {
  # Creating the ssh keys
  mkdir -r /home/client/.ssh
  chown client /home/client/.ssh
  chmod 700 /home/client/.ssh

  touch /home/client/.ssh/authorized_keys
  chown client /home/client/.ssh/authorized_keys
  
  # write keys to client authorized keys
  echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8Sf/vfRY+SGp6fS5ENgGPh3gAAL6EtGxoeku2g90JSP3hQh/GaszQotwYF3Kw7A4VtivSkUx63YKgvJXD73sxV+wHF9XTnY2OYo+ow7TqyNP9kG/Ld/nnZ7Pj5yuXXKzCUlhvBimUYEev3iePZ67Aqq6gMEypiDooiRi3F72OVk9ZxJsZU8Caa7lBYwg7YPsfsa+KjaOnENy/Sz6fkKat3RfAZ75bqOjsSIrRNoIdUoF2JleZOJ4QfAbZQcuijYHC3BaYlrrmd4WwI0t14N126//E5QRnnSyUdfFS4gAlqgQKN6oSCAEcYzs1eO72xs9CdW/Rj6s8cdB1UwtPckWV" >> /home/client/.ssh/authorized_keys
  chmod 600 /home/client/.ssh/authorized_keys
}

setup_certificates() {
  dlog "- copy root.cer to path in TrustedUserCAKeys found in sshd_config"
  mkdir -r /etc/credentials
  mv $TOOL_PATH/credentials/root.cer /etc/credentials
  mv $TOOL_PATH/credentials/clients.pem /etc/credentials

  dlog "- Adding TrustedUserCAKeys to sshd_config"
  echo "TrustedUserCAKeys /etc/credentials/root.cer" >> /etc/ssh/sshd_config
 
  dlog "- Create Server Certificates"
  chmod +x "$TOOL_PATH/certificate_generation/setup_server.sh"
  cd /etc/credentials
  $TOOL_PATH/certificate_generation/setup_server.sh "$current_ip" "$(hostname)"
  cd -
}

full_device_setup(){
  log "SET Date Time for correct certificate validation"
  set_date
  
  log "SET Root password"
  echo 'root:$6$WQBiS3eMvOMsmsDy$nebw3AB8weP3mqP/1qqcJsN/Xh.CW5S2hsSHMVSxdH5sqEMdJZzzDfmcoBeZeNNh43JqXSquoRES3D4bgxKBy.' |chpasswd -e

  log "SET Hostname:"
  echo "PROMPT: Please enter the hostname of the device"
  read HOSTNAME

  log "SETUP Hostname"
  echo "$HOSTNAME" > /etc/hostname
  echo "127.0.0.1 $HOSTNAME" >> /etc/hosts
  echo 
  hostname $HOSTNAME
  /etc/init.d/hostname.sh restart

  log "Add users"
  add_users
  log "Setup Polling"
  setup_polling
  log "Setup Python"
  setup_python
  log "Setup SSH"
  setup_ssh
  
  log "Load Installation Files"
  load_installation_files
  log "Setup Certificates"
  setup_certificates
  log "Install Services"
  install_services
  log "Cleanup"
  cleanup_installation_files
  log "Installation READY"
}

full_device_setup