#!/bin/sh

# ADDING USERS

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

# Creating file and adding content
touch /home/manager/testConnection.sh
echo 'ping -c 1 8.8.8.8' > /home/manager/testConnection.sh

#adding the rights for that file
chown :managerGroup /home/manager/testConnection.sh
chmod 771 /home/manager/testConnection.sh

#adding the file to the cronjob
echo '* * * * * root /home/manager/testConnection.sh' >> /etc/crontab

# Adding sudo rights
echo 'client ALL=(root) NOPASSWD: /usr/bin/less /home/manager/*' >> /etc/sudoers

# Pip things
python3 -m pip install --trusted-host pypi.python.org --trusted-host files.pythonhosted.org --trusted-host pypi.org --upgrade pip
pip install aiocoap --trusted-host pypi.python.org --trusted-host files.pythonhosted.org --trusted-host pypi.org
pip install linkHeader --trusted-host pypi.python.org --trusted-host files.pythonhosted.org --trusted-host pypi.org
pip install flask --trusted-host pypi.python.org --trusted-host files.pythonhosted.org --trusted-host pypi.org
pip install flask_login --trusted-host pypi.python.org --trusted-host files.pythonhosted.org --trusted-host pypi.org
pip install flask_wtf --trusted-host pypi.python.org --trusted-host files.pythonhosted.org --trusted-host pypi.org
pip install gevent --trusted-host pypi.python.org --trusted-host files.pythonhosted.org --trusted-host pypi.org
pip install gevent.server --trusted-host pypi.python.org --trusted-host files.pythonhosted.org --trusted-host pypi.org

# Getting the files
cd /home/client
wget https://github.com/victorGoeman/velcroTools/archive/refs/tags/v5.zip
unzip v5.zip

# Creating the ssh keys
mkdir /home/client/.ssh
chown client /home/client/.ssh
chmod 700 /home/client/.ssh

touch /home/client/.ssh/authorized_keys
chown client /home/client/.ssh/authorized_keys

#copy root.cer to path in TrustedUserCAKeys found in sshd_config
mkdir /etc/credentials
mv /home/client/velcroTools-5/credentials/root.cer /etc/credentials

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
    mv /home/client/velcroTools-5/credentials/server_192_168_42_5$index.* /etc/credentials
  elif [[ $index -eq 10 ]]
  then
    mv /home/client/velcroTools-5/credentials/server_192_168_42_60.* /etc/credentials
fi


echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDAT/4ZBqVsrdgwnHcbGWdRQTXjT6pjF0lBIZHiGr5953WSSYUjLYtGnIlNutfsnZyP0SR9qKSgjuQsqZ3/VjrFMvTXQECT3hE3snXG/jJ1+ZPVJf1pzz00JnVeZrASM7hAnR+ak+SfPWKRWcvUwPVbafxB7gIzcGrqZA9MSBkTnAndMbQ7dtpcyWc5bo9HhB3f+W5WBF/n0sID9ZFTKBbME3AugD6g9/YZhLaXSlB3auiKAT6H7u4NrVMCDO2n6WE1IHZ5xwo2yJhjFx5mqRfqVA8VyjP90GBJx3JQrRKHjz64963sOw2ldzewMopp4QQSw6OxCZbVmvE8xETIM3aUPZjXQE1uMTzdt3hT8eemqMrJxIA88cj/hsmNRXIevV/fvZmmWY/tQISSlnz0iZjrXeIbzbNCSGwvknXlqsZ3d62y7zy2APX/WNDQJNX4BpgVAROi8h8z1xOslLmPp7ZDiRkkphgQkqPzLUG1mHfWwVckHfyw+BHd1xB6yBcrQV8= client@raspberrypi3-64" >> /home/client/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8Sf/vfRY+SGp6fS5ENgGPh3gAAL6EtGxoeku2g90JSP3hQh/GaszQotwYF3Kw7A4VtivSkUx63YKgvJXD73sxV+wHF9XTnY2OYo+ow7TqyNP9kG/Ld/nnZ7Pj5yuXXKzCUlhvBimUYEev3iePZ67Aqq6gMEypiDooiRi3F72OVk9ZxJsZU8Caa7lBYwg7YPsfsa+KjaOnENy/Sz6fkKat3RfAZ75bqOjsSIrRNoIdUoF2JleZOJ4QfAbZQcuijYHC3BaYlrrmd4WwI0t14N126//E5QRnnSyUdfFS4gAlqgQKN6oSCAEcYzs1eO72xs9CdW/Rj6s8cdB1UwtPckWV" >> /home/client/.ssh/authorized_keys
chmod 600 /home/client/.ssh/authorized_keys

# Creating files for running the different services
touch /home/client/runCoAP.sh
touch /home/client/runHTTP.sh
touch /home/client/runTelnet.sh
touch /home/client/runRest.sh

echo "ps | grep CoapServer.py | grep -v grep && echo 'Running..' || python3 /home/client/velcroTools-5/CoAP/CoapServer.py "  > /home/client/runCoAP.sh
echo "ps | grep dvd_telnet.py | grep -v grep && echo 'Running..' || python3 /home/client/velcroTools-5/Telnet/dvd_telnet.py" > /home/client/runTelnet.sh
echo "ps | grep HTTP/main.py | grep -v grep && echo 'Running..' || python3 /home/client/velcroTools-5/HTTP/main.py >/dev/null" > /home/client/runHTTP.sh
echo "ps | grep dvd_rest.py | grep -v grep && echo 'Running..' || python3 /home/client/velcroTools-5/Rest/dvd_rest.py" > /home/client/runRest.sh

echo '*/5 * * * * client /home/client/runCoAP.sh' >> /etc/crontab
echo '*/5 * * * * root /home/client/runTelnet.sh' >> /etc/crontab
echo '*/5 * * * * root /home/client/runHTTP.sh' >> /etc/crontab
echo '*/5 * * * * root /home/client/runRest.sh' >> /etc/crontab

chmod +x /home/client/run*.sh

# Set root password
echo "TODO: add root password if not done yet"

#Removing
rm /home/client/v5.zip
rm -rf /home/client/credentials
rm -rf /home/client/certificate_generation
rm /home/client/setup.sh

