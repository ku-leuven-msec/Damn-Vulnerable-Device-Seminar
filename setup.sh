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
echo 'www-data ALL=(root) NOPASSWD: /usr/bin/less /home/manager/*' >> /etc/sudoers

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
wget https://github.com/victorGoeman/velcroTools/archive/refs/tags/v3.zip
unzip v3.zip

# Creating the ssh keys
mkdir /home/client/.ssh
chown client /home/client/.ssh
chmod 700 /home/client/.ssh

touch /home/client/.ssh/authorized_keys
chown client /home/client/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDAT/4ZBqVsrdgwnHcbGWdRQTXjT6pjF0lBIZHiGr5953WSSYUjLYtGnIlNutfsnZyP0SR9qKSgjuQsqZ3/VjrFMvTXQECT3hE3snXG/jJ1+ZPVJf1pzz00JnVeZrASM7hAnR+ak+SfPWKRWcvUwPVbafxB7gIzcGrqZA9MSBkTnAndMbQ7dtpcyWc5bo9HhB3f+W5WBF/n0sID9ZFTKBbME3AugD6g9/YZhLaXSlB3auiKAT6H7u4NrVMCDO2n6WE1IHZ5xwo2yJhjFx5mqRfqVA8VyjP90GBJx3JQrRKHjz64963sOw2ldzewMopp4QQSw6OxCZbVmvE8xETIM3aUPZjXQE1uMTzdt3hT8eemqMrJxIA88cj/hsmNRXIevV/fvZmmWY/tQISSlnz0iZjrXeIbzbNCSGwvknXlqsZ3d62y7zy2APX/WNDQJNX4BpgVAROi8h8z1xOslLmPp7ZDiRkkphgQkqPzLUG1mHfWwVckHfyw+BHd1xB6yBcrQV8= client@raspberrypi3-64" >> /home/client/.ssh/authorized_keys
chmod 600 /home/client/.ssh/authorized_keys

# Creating a file for running the different services
touch /home/client/run.sh
echo 'python3 /home/client/velcroTools-3/CoAP/CoapServer.py & python3 /home/client/velcroTools-3/Telnet/dvd_telnet.py & python3 /home/client/velcroTools-3/HTTP/main.py >/dev/null' > /home/client/run.sh
echo 'python3 /home/client/velcroTools-3/Telnet/dvd_telnet.py' > /home/root/runRoot.sh 
chmod +x /home/client/run.sh

echo "TODO: You still need to manually start the runRoot.sh file as root"
echo "TODO: You still need to manually start the run.sh file as client"


# Set root password
echo "TODO: add root password if not done yet"

echo 'done'
echo 'now we should also remove this file'
 
