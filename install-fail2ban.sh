#!/bin/bash

## Sanity Checks and automagic
function root-check() {
if [[ "$EUID" -ne 0 ]]; then
  echo "Sorry, you need to run this as root"
  exit
fi
}

## Root Check
root-check

## Detect Operating System
function dist-check() {
  if [ -e /etc/centos-release ]; then
    DISTRO="CentOS"
  elif [ -e /etc/debian_version ]; then
    DISTRO=$( lsb_release -is )
  elif [ -e /etc/arch-release ]; then
    DISTRO="Arch"
  elif [ -e /etc/fedora-release ]; then
    DISTRO="Fedora"
  elif [ -e /etc/redhat-release ]; then
    DISTRO="Redhat"
  else
    echo "Your distribution is not supported (yet)."
    exit
  fi
}

## Check distro
dist-check

## Creating The Function
function install-failtwoban() {
  if [ "$DISTRO" == "Ubuntu" ]; then
    echo "Updating package list..."
    apt-get update
    apt-get install build-essential haveged linux-headers-$(uname -r) fail2ban -y
  elif [ "$DISTRO" == "Debian" ]; then
    echo "Updating package list..."
    apt-get update
    apt-get install build-essential haveged linux-headers-$(uname -r) fail2ban -y
  elif [ "$DISTRO" == "Raspbian" ]; then
    echo "Updating package list..."
    apt-get update
    apt-get install build-essential haveged linux-headers-$(uname -r) fail2ban -y
  elif [ "$DISTRO" == "CentOS" ]; then
    yum update -y
    yum install epel-release haveged kernel-devel -y
    yum install fail2ban -y
  fi
}

## Run Function
install-failtwoban

## Restart Apache2
function failtwoban-restart() {
if pgrep systemd-journal; then
  systemctl enable fail2ban
  systemctl restart fail2ban
else
   service restart fail2ban
fi
}

## Run Function
failtwoban-restart
