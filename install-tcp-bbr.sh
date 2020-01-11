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

## Start Installation
function install-bbr() {
    if [ "$DISTRO" == "Ubuntu" ]; then
        apt-get update
        apt-get upgrade -y
        apt-get dist-upgrade -y
        apt-get install build-essential linux-headers-$(uname -r) haveged -y
        apt-get upgrade linux-base -y
        apt-get clean -y
        apt-get autoremove -y
        modprobe tcp_bbr
        echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
        echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf 
        echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
        sysctl -p
        uname -r
        sysctl net.ipv4.tcp_available_congestion_control
        sysctl net.ipv4.tcp_congestion_control
        sysctl net.core.default_qdisc
        lsmod | grep bbr
    elif [ "$DISTRO" == "Debian" ]; then
        apt-get update
        apt-get upgrade -y
        apt-get dist-upgrade -y
        apt-get install build-essential linux-headers-$(uname -r) haveged -y
        apt-get upgrade linux-base -y
        apt-get clean -y
        apt-get autoremove -y
        modprobe tcp_bbr
        echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
        echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf 
        echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
        sysctl -p
        uname -r
        sysctl net.ipv4.tcp_available_congestion_control
        sysctl net.ipv4.tcp_congestion_control
        sysctl net.core.default_qdisc
        lsmod | grep bbr
    elif [ "$DISTRO" == "Rasbian" ]; then
        apt-get update
        apt-get upgrade -y
        apt-get dist-upgrade -y
        apt-get install build-essential raspberrypi-kernel-headers haveged -y
        apt-get upgrade linux-base -y
        apt-get clean -y
        apt-get autoremove -y
        modprobe tcp_bbr
        echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
        echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf 
        echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
        sysctl -p
        uname -r
        sysctl net.ipv4.tcp_available_congestion_control
        sysctl net.ipv4.tcp_congestion_control
        sysctl net.core.default_qdisc
        lsmod | grep bbr
    elif [ "$DISTRO" == "CentOS" ]; then
        yum update -y
        yum install epel-release -y
        yum autoremove -y
        modprobe tcp_bbr
        echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
        echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf 
        echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
        sysctl -p
        uname -r
        sysctl net.ipv4.tcp_available_congestion_control
        sysctl net.ipv4.tcp_congestion_control
        sysctl net.core.default_qdisc
        lsmod | grep bbr
fi
}

## Install Google BBR
install-bbr
