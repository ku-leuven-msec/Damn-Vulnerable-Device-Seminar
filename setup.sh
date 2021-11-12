#!/bin/sh


#general functions:
get_latest_release() {
  cd $TMP_PATH
  wget -O - -o /dev/null "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
  grep '"tag_name":' |                                            # Get tag line
  sed -E 's/.*"(v[^"]+)".*/\1/'                                    # Pluck JSON value
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
GIT_HUB="ku-leuven-msec/Damn-Vulnerable-Device-Seminar"
TMP_PATH="/tmp/dvd"
mkdir -p $TMP_PATH
REL=$(get_latest_release $GIT_HUB)
TOOL_PATH="$TMP_PATH/Damn-Vulnerable-Device-Seminar-$REL"
SERVICE_PATH="/opt/dvd/"

# ADDING USERS
add_users() {
  # Adding least privileged user: www-data
  useradd -p '$6$vOsShJfzJ$nspR/.gahnFFRBL9hrTkWCwr8fCjhkIaEyABvCCpCVL6p1G3dZVEhvmbcOg2Bh1OG.a9ZmKkzwo2V5ZDOin73/' client
  mkdir /home/client

  # Adding bit more privileged user: manager
  useradd -p '$6$dY5hO/6B48/9D.66$QHHDlmdkw.CHtzQg.W/e7s8SnGJaJgwVYwKzLu1vB6ZTeKBb2BXj1xc7wJJUl7nFgUXy6AHf/6z63yOPuXBT7/' manager
  mkdir /home/manager

  # Adding group
  groupadd managerGroup

  # adding manager to that group 
  usermod -a -G managerGroup manager 

  # Adding sudo rights
  echo 'client ALL=(root) NOPASSWD: /usr/bin/less /home/manager/*' >> /etc/sudoers

}

setup_polling() {
  # Creating file and adding content
  touch /home/manager/checkNetwork.sh
  echo 'ping -c 1 google.com' > /home/manager/checkNetwork.sh

  #adding the rights for that file
  chown :managerGroup /home/manager/checkNetwork.sh
  chmod 771 /home/manager/checkNetwork.sh

  #adding the file to the cronjob
  echo '* * * * * root /home/manager/checkNetwork.sh' >> /etc/crontab
}

setup_python() {
  pip config set global.trusted-host "pypi.org pypi.python.org files.pythonhosted.org"
  python3 -m pip install --upgrade pip
  pip install daemonize
}


monitor_service() {
  service=$1
  usr=$2
  echo '*/5 * * * * $usr $SERVICE_PATH/check_daemon.sh $service' >> /etc/crontab
}

install_service() {
  if [ -f "$SERVICE_PATH/$1/server.py" ]; then
    if [ -f "$SERVICE_PATH/$1/requirements.txt" ]; then
      pip install -r "$SERVICE_PATH/$1/requirements.txt"
    fi
    monitor_service $1
  fi
}

install_services() {
  mv "$TOOL_PATH/services" "$SERVICE_PATH"
  chmod 751 "$SERVICE_PATH/check_daemon.sh"
  
  for d in "$SERVICE_PATH"*
  do
      echo "Install $d service"
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
  rm $TMP_PATH
}

setup_ssh() {
  # Creating the ssh keys
  mkdir /home/client/.ssh
  chown client /home/client/.ssh
  chmod 700 /home/client/.ssh

  touch /home/client/.ssh/authorized_keys
  chown client /home/client/.ssh/authorized_keys
  
  # write keys to client authorized keys
  echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8Sf/vfRY+SGp6fS5ENgGPh3gAAL6EtGxoeku2g90JSP3hQh/GaszQotwYF3Kw7A4VtivSkUx63YKgvJXD73sxV+wHF9XTnY2OYo+ow7TqyNP9kG/Ld/nnZ7Pj5yuXXKzCUlhvBimUYEev3iePZ67Aqq6gMEypiDooiRi3F72OVk9ZxJsZU8Caa7lBYwg7YPsfsa+KjaOnENy/Sz6fkKat3RfAZ75bqOjsSIrRNoIdUoF2JleZOJ4QfAbZQcuijYHC3BaYlrrmd4WwI0t14N126//E5QRnnSyUdfFS4gAlqgQKN6oSCAEcYzs1eO72xs9CdW/Rj6s8cdB1UwtPckWV" >> /home/client/.ssh/authorized_keys
  chmod 600 /home/client/.ssh/authorized_keys
}

setup_certificates() {
  #copy root.cer to path in TrustedUserCAKeys found in sshd_config
  mkdir /etc/credentials
  mv $TOOL_PATH/credentials/root.cer /etc/credentials
  mv $TOOL_PATH/credentials/clients.pem /etc/credentials

  # Adding TrustedUserCAKeys to sshd_config
  echo "TrustedUserCAKeys /etc/credentials/root.cer" >> /etc/ssh/sshd_config
 
  #Create Server Certificates
  chmod +x "$TOOL_PATH/certificate_generation/setup_server.sh"
  cd /etc/credentials
  $TOOL_PATH/certificate_generation/setup_server.sh "$current_ip" "$(hostname)"
  cd -
}

full_device_setup(){
  # SET Date Time for correct certificate validation
  rdate -s time.nist.gov
  
  # SET Root password
  echo 'root:$6$WQBiS3eMvOMsmsDy$nebw3AB8weP3mqP/1qqcJsN/Xh.CW5S2hsSHMVSxdH5sqEMdJZzzDfmcoBeZeNNh43JqXSquoRES3D4bgxKBy.' |chpasswd -e

  # SET Hostname:
  echo "PROMPT: Please enter the hostname of the device"
  read HOSTNAME

  #SETUP Hostname
  echo "$HOSTNAME" > /etc/hostname
  echo "127.0.0.1 $HOSTNAME" >> /etc/hosts
  echo 
  hostname $HOSTNAME
  /etc/init.d/hostname.sh restart

  add_users

  setup_polling
  setup_python
  setup_ssh
  
  load_installation_files
  setup_certificates
  install_services

  cleanup_installation_files
}

full_device_setup