#!/bin/sh

ALPINE_VERSION=v$(cut -d'.' -f1,2 /etc/alpine-release)

pre_setup(){
  log "Enabling community packages"
  echo https://dl-cdn.alpinelinux.org/alpine/$ALPINE_VERSION/main > /etc/apk/repositories
  echo https://dl-cdn.alpinelinux.org/alpine/$ALPINE_VERSION/community >> /etc/apk/repositories
  echo https://dl-cdn.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories
  apk update

  log "Installing python and pip"
  apk add python3
  apk add py3-pip

  log "Installing sudo, shadow and bash"
  apk add sudo
  apk add shadow
  apk add bash

  log "Preparing some files and folders for the installation of the DVD"
  touch /etc/login.defs
  mkdir /etc/default
  touch /etc/default/useradd
}
pre_setup
