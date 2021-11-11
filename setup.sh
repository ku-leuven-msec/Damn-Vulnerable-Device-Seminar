#!/bin/sh
#config
REL=get_latest_release "victorGoeman/velcroTools"

TMP_PATH="/home/client/tmp"
TOOL_PATH="$TMP_PATH/velcroTools-$REL"

SERVICE_PATH="/opt/dvd/"

#general functions:

get_latest_release() {
  cd TMP_PATH
  wget -O - -o /dev/null "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
  grep '"tag_name":' |                                            # Get tag line
  sed -E 's/.*"(v[^"]+)".*/\1/'                                    # Pluck JSON value
}

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
  
  wget "https://github.com/victorGoeman/velcroTools/archive/refs/tags/v$REL.zip"
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
  echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDAT/4ZBqVsrdgwnHcbGWdRQTXjT6pjF0lBIZHiGr5953WSSYUjLYtGnIlNutfsnZyP0SR9qKSgjuQsqZ3/VjrFMvTXQECT3hE3snXG/jJ1+ZPVJf1pzz00JnVeZrASM7hAnR+ak+SfPWKRWcvUwPVbafxB7gIzcGrqZA9MSBkTnAndMbQ7dtpcyWc5bo9HhB3f+W5WBF/n0sID9ZFTKBbME3AugD6g9/YZhLaXSlB3auiKAT6H7u4NrVMCDO2n6WE1IHZ5xwo2yJhjFx5mqRfqVA8VyjP90GBJx3JQrRKHjz64963sOw2ldzewMopp4QQSw6OxCZbVmvE8xETIM3aUPZjXQE1uMTzdt3hT8eemqMrJxIA88cj/hsmNRXIevV/fvZmmWY/tQISSlnz0iZjrXeIbzbNCSGwvknXlqsZ3d62y7zy2APX/WNDQJNX4BpgVAROi8h8z1xOslLmPp7ZDiRkkphgQkqPzLUG1mHfWwVckHfyw+BHd1xB6yBcrQV8= client@raspberrypi3-64" >> /home/client/.ssh/authorized_keys
  echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8Sf/vfRY+SGp6fS5ENgGPh3gAAL6EtGxoeku2g90JSP3hQh/GaszQotwYF3Kw7A4VtivSkUx63YKgvJXD73sxV+wHF9XTnY2OYo+ow7TqyNP9kG/Ld/nnZ7Pj5yuXXKzCUlhvBimUYEev3iePZ67Aqq6gMEypiDooiRi3F72OVk9ZxJsZU8Caa7lBYwg7YPsfsa+KjaOnENy/Sz6fkKat3RfAZ75bqOjsSIrRNoIdUoF2JleZOJ4QfAbZQcuijYHC3BaYlrrmd4WwI0t14N126//E5QRnnSyUdfFS4gAlqgQKN6oSCAEcYzs1eO72xs9CdW/Rj6s8cdB1UwtPckWV" >> /home/client/.ssh/authorized_keys
  chmod 600 /home/client/.ssh/authorized_keys
}

setup_certificates() {
  #copy root.cer to path in TrustedUserCAKeys found in sshd_config
  mkdir /etc/credentials
  mv $TOOL_PATH/credentials/root.cer /etc/credentials

  # Adding TrustedUserCAKeys to sshd_config
  echo "TrustedUserCAKeys /etc/credentials/root.cer" >> /etc/ssh/sshd_config

  echo "PROMPT: Please give the index of the device (1-10)"
  read index
  HOSTNAME="DVD$index"
  echo "$HOSTNAME" > /etc/hostname
  echo "127.0.0.1 $HOSTNAME" >> /etc/hosts
  hostname $HOSTNAME
  /etc/init.d/hostname.sh restart

  if [[ $index -lt 10 ]]
    then
      mv $TOOL_PATH/credentials/server_192_168_42_5$index.cer /etc/credentials/server.cer
      mv $TOOL_PATH/credentials/server_192_168_42_5$index.key /etc/credentials/server.key
    elif [[ $index -eq 10 ]]
    then
      mv $TOOL_PATH/credentials/server_192_168_42_60.cer /etc/credentials/server.cer
      mv $TOOL_PATH/credentials/server_192_168_42_60.key /etc/credentials/server.key
  fi
}

full_device_setup(){
  # SET Date Time for correct certificate validation
  rdate -s time.nist.gov
  
  # SET Root password
  echo 'root:$6$WQBiS3eMvOMsmsDy$nebw3AB8weP3mqP/1qqcJsN/Xh.CW5S2hsSHMVSxdH5sqEMdJZzzDfmcoBeZeNNh43JqXSquoRES3D4bgxKBy.' |chpasswd -e
  
  add_users

  setup_polling
  setup_python
  setup_ssh
  
  load_installation_files
  setup_certificates
  install_services

  cleanup_installation_files
}

