# Damn Vulnerable Device Seminar
Security Analysis on IoT using basic Pentesting Tools

## Requiremens
* Raspberry Pi3
* Support Fixed IPs for the device

## Setup
* Create DVD Image for the Raspberry Pi using Yocto, by following the steps explained in this [readme.txt](Yocto/readme.txt).
* Install the image on the device.
* Make sure the device gets a fixed IP from the DHCP service.
* Get SSH root access to the device (password is empty).
* Copy the [setup](setup.sh) file to the device, either using scp, or creating a file with vi and copy/paste into the console. The latter requires to make the file executable (i.e., chmod +x setup.sh).
* Run the ./setup.sh file. This will install all necessary files and services onto the device.
* During the installation it will ask for a hostname of the device. Give it a name such as DVD1, DVD2, ..., but make sure the names don't overlap if you install multiple devices n the network.

## Android APK file
The android apk that comes with the Damn-Vulnerable-Device can be downloaded [here](Android/app/build/outputs/apk/debug/app-debug.apk).

The full Android project is in this repository in the ([Android](Android)) folder.

## Kali VM
For a hands-on seminar, it is easier to prepare a kali VM, containing a number of files on the desktop.
* The Android APK file
* A pcap trace file from capturing the communication with ettercap (can be generated as explained in the tutorial text)
* The result of an analyses of the firmware with Emba (also following the steps in the tutorial or on the site of Embe). 

Note: to analyse the firmware with Emba, you may have to retrieve the configured device from the RPi SD card using e.g., the *dd* command.
