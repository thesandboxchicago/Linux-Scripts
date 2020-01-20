#!/bin/bash
# https://github.com/complexorganizations/shadowsocks-install

## Sanity Checks and automagic
function root-check() {
if [[ "$EUID" -ne 0 ]]; then
  echo "Sorry, you need to run this as root"
  exit
fi
}

## Check Root
root-check

## Detect Operating System
function dist-check() {
  if [ -e /etc/centos-release ]; then
    DISTRO="CentOS"
  elif [ -e /etc/debian_version ]; then
    DISTRO=$(lsb_release -is)
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

## Check Operating System
dist-check

  ## Question 1: Determine host port
function set-port() {
  echo "What port do you want Shadowsocks to listen to?"
  echo "   1) 80 (Recommended)"
  echo "   2) 443 (Advanced)"
  until [[ "$PORT_CHOICE" =~ ^[1-2]$ ]]; do
    read -rp "Port choice [1-2]: " -e -i 1 PORT_CHOICE
  done

  ## Apply port response
  case $PORT_CHOICE in
    1)
    SERVER_PORT="80"
    ;;
    2)
    SERVER_PORT="443"
    ;;
  esac
}
  ## Set the port number
  set-port

## Determine password
function shadowsocks-password() {
echo "Choose your password"
echo "   1) Random (Recommended)"
echo "   2) Custom (Advanced)"
until [[ "$PASSWORD_CHOICE" =~ ^[1-2]$ ]]; do
  read -rp "Password choice [1-2]: " -e -i 1 PASSWORD_CHOICE
done

## Apply port response
case $PORT_CHOICE in
  1)
  PASSWORD_CHOICE="(head /dev/random | tr -dc '[:graph:]' | fold -w20 | sed '$d' | shuf -n1)"
  ;;
  2)
  PASSWORD_CHOICE="read -rp "Password " -e PASSWORD_CHOICE"
  ;;
esac
}

## Password
shadowsocks-password

 ## Do you want to disable IPv4 or IPv6 or leave them both enabled?
  function disable-ipvx() {
    echo "Do you want to disable IPv4 or IPv6 on the server?"
    echo "   1) No (Recommended)"
    echo "   2) IPV4"
    echo "   3) IPV6"
    until [[ "$DISABLE_HOST" =~ ^[1-3]$ ]]; do
      read -rp "Disable Host Choice [1-3]: " -e -i 1 DISABLE_HOST
    done
    case $DISABLE_HOST in
    1)
      DISABLE_HOST="$(
        echo "net.ipv4.ip_forward=1" >>/etc/sysctl.d/shadowsocks.conf
        echo "net.ipv6.conf.all.forwarding=1" >>/etc/sysctl.d/shadowsocks.conf
        sysctl --system
      )"
      ;;
    2)
      DISABLE_HOST="$(
        echo "net.ipv4.conf.all.disable_ipv4=1" >>/etc/sysctl.d/shadowsocks.conf
        echo "net.ipv4.conf.default.disable_ipv4=1" >>/etc/sysctl.d/shadowsocks.conf
        echo "net.ipv6.conf.all.forwarding=1" >>/etc/sysctl.d/shadowsocks.conf
        sysctl --system
      )"
      ;;
    3)
      DISABLE_HOST="$(
        echo "net.ipv6.conf.all.disable_ipv6 = 1" >>/etc/sysctl.d/shadowsocks.conf
        echo "net.ipv6.conf.default.disable_ipv6 = 1" >>/etc/sysctl.d/shadowsocks.conf
        echo "net.ipv6.conf.lo.disable_ipv6 = 1" >>/etc/sysctl.d/shadowsocks.conf
        echo "net.ipv4.ip_forward=1" >>/etc/sysctl.d/shadowsocks.conf
        sysctl --system
      )"
      ;;
    esac
  }

  ## Disable Ipv4 or Ipv6
  disable-ipvx
  
  function v2ray-install() {
  CHECK_ARCHITECTURE=$(dpkg --print-architecture)
  FILE_NAME=$(v2ray-plugin-linux-$CHECK_ARCHITECTURE-v1.2.0.tar.gz)
      ## Installation Begins Here
      cd /etc/shadowsocks-libev/
      wget https://github.com/shadowsocks/v2ray-plugin/releases/download/v1.2.0/$FILE_NAME
      tar xvzf $FILE_NAME
      rm $FILE_NAME
  }
  
  v2ray-install
  
function limits-conf-install() {
  echo '* soft nofile 51200' >> /etc/security/limits.conf
  echo '* hard nofile 51200' >> /etc/security/limits.conf
  ulimit -n 51200
}

## Set Limits
limits-conf-install

function sysctl-install() {
  ## Ammend configuration specifics for sysctl.conf
  echo \
'fs.file-max = 51200
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 4096
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mem = 25600 51200 102400
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_congestion_control = hybla' \
  >> /etc/sysctl.d/shadowsocks.conf
}

## Install SystemCTL
sysctl-install

## bbr-optimization aka make SS super fast.
function bbr-optimization() {
  if [ "$DISTRO" == "Ubuntu" ]; then
    sysctl-install
    modprobe tcp_bbr
    echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
    echo "net.core.default_qdisc=fq \nnet.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
  elif [ "$DISTRO" == "Debian" ]; then
    modprobe tcp_bbr
    echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
    echo "net.core.default_qdisc=fq \nnet.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
  elif [ "$DISTRO" == "Raspbian" ]; then
    modprobe tcp_bbr
    echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
    echo "net.core.default_qdisc=fq \nnet.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
  fi
}

## BBR Install
bbr-optimization

function install-shadowsocks() {
    ## Installation begins here.
  if [ "$DISTRO" == "Ubuntu" ]; then
    apt-get update
    apt-get install linux-headers-$(uname -r) shadowsocks-libev haveged cron screen -y
  elif [ "$DISTRO" == "Debian" ]; then
    apt-get update
    apt-get install linux-headers-$(uname -r) shadowsocks-libev haveged cron screen -y
  elif [ "$DISTRO" == "Raspbian" ]; then
    apt-get update
    apt-get install raspberrypi-kernel-headers shadowsocks-libev haveged cron screen -y
  elif [ "$DISTRO" == "CentOS" ]; then
    yum update -y
    cd /etc/yum.repos.d/
    curl -O https://copr.fedorainfracloud.org/coprs/librehat/shadowsocks/repo/epel-7/librehat-shadowsocks-epel-7.repo
    yum install linux-headers-$(uname -r) shadowsocks-libev haveged cron screen -y
  elif [ "$DISTRO" == "RedHat" ]; then
    yum update -y
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    yum install linux-headers-$(uname -r) shadowsocks-libev haveged cron screen -y
  elif [ "$DISTRO" == "Fedora" ]; then
    dnf update -y
    dnf copr enable librehat/shadowsocks
    dnf install linux-headers-$(uname -r) shadowsocks-libev haveged cron screen -y
  elif [ "$DISTRO" == "Arch" ]; then
    pacman -S update
    pacman -S install linux-headers-$(uname -r) shadowsocks-libev haveged cron screen -y
  fi
}

## Install Shadowsocks
install-shadowsocks

function shadowsocks-configuration() {
  echo \
'{"server":"0.0.0.0",
"server_port":$PORT_CHOICE,
"password":"$PASSWORD_CHOICE",
"method":"aes-256-cfb"
"plugin":"/etc/shadowsocks-libev/$FILE_NAME",
"plugin_opts":"server"
}' >> /etc/shadowsocks-libev/config.json
}

## Shadowsocks Config
shadowsocks-configuration

function shadowsocks-startup-install() {
echo "#!/bin/sh
if [ -z "$STY" ]; then exec screen -dm -S screenName /bin/bash "$0"; fi
ss-server
exit 0" >> /etc/shadowsocks-libev/ss-startup.sh
chmod a+x /etc/shadowsocks-libev/ss-startup.sh
echo "@reboot /etc/shadowsocks-libev/ss-startup.sh" >> /etc/crontab
}

## Shadowsocks Startup
shadowsocks-startup-install

## Uninstall Shadowsocks
function uninstall-shadowsocks() {
  if [ "$DISTRO" == "Ubuntu" ]; then
    apt-get remove --purge linux-headers-$(uname -r) shadowsocks-libev haveged cron screen -y
  elif [ "$DISTRO" == "Debian" ]; then
    apt-get remove --purge linux-headers-$(uname -r) shadowsocks-libev haveged cron screen -y
  elif [ "$DISTRO" == "Raspbian" ]; then
    apt-get remove --purge raspberrypi-kernel-headers shadowsocks-libev haveged cron screen -y
  else
  sed -i 's/\* soft nofile 51200//d' /etc/security/limits.conf
  sed -i 's/\* hard nofile 51200//d' /etc/security/limits.conf
  rm /etc/shadowsocks-libev/ss-startup.sh
  sed -i 's#\@reboot /etc/shadowsocks-libev/ss-startup.sh##d' /etc/crontab
  mv /etc/sysctl.conf.old /etc/sysctl.conf
  fi
}
