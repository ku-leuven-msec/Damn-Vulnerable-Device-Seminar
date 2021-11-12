How make your own yocto build
------------------------------
1. Install Yocto
2. Download this git repo in your poky https://github.com/agherzan/meta-raspberrypi
3. execute:
cd poky
cd meta-raspberry
source ../oe-init-build-env
4. Use the local.conf that you can see in this build
5. bitbake core-image-base
6. Wait an hour
7. Enjoy