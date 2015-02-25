#!/bin/bash
# Check for root access / sudo
if [ `id -u` -ne '0' ]; then
  echo "This must be ran with sudo/root access." >&2
  exit 1
 else
   # Warn user
   read -p "This script was made for Ubuntu, RUN WITH CAUTION! Are you sure you want to run? (y/n?)" -n 1 -r
    echo    # (optional) move to a new line
     if [[ $REPLY =~ ^[Yy]$ ]]
      then
       echo "CHANGING SSH PORT TO DYNAMIC PORT"
        port=$(( 100+( $(od -An -N2 -i /dev/random) )%(40000-1024+1) ))
        while :
        do(echo >/dev/tcp/localhost/$port) &>/dev/null &&  port=$(( 100+( $(od -An -N2 -i /dev/random) )%(40000-1000+1) )) || break
        done
        sed -ie 's/Port.*[0-9]$/Port '$port'/gI' /etc/ssh/sshd_config
       echo "INSTALLING DUO SECURITY MODULE"
       echo "Installing dependencies..."
        apt-get install make libssl-dev
        cd /tmp
       echo "Downloading Duo Security module..."
       wget https://dl.duosecurity.com/duo_unix-latest.tar.gz
       echo "Unzipping..."
       tar zxf duo_unix-latest.tar.gz
       echo "Installing..."
       cd duo_unix-1.9.14
       ./configure --prefix=/usr && make && sudo make install
       echo "CONFIGURING DUO SECURITY MODULE"
       echo "..............................."
       echo -n "Enter your Duo security integration key: "
        read integration_key
       echo -n "Enter your Duo security Secret key: "
        read secret_key
       echo -n "Enter your Duo security API key: "
        read api_key
       echo "Setting Duo Security on SSH Server"
       echo 'ForceCommand /usr/sbin/login_duo' >> /etc/ssh/sshd_config
        sed -ie 's/INTEGRATION_KEY/'$integration_key'/' /etc/duo/login_duo.conf
        sed -ie 's/SECRET_KEY/'$secret_key'/' /etc/duo/login_duo.conf
        sed -ie 's/API_HOSTNAME/'$api_key'/' /etc/duo/login_duo.conf
      echo "................................"
      echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      echo "................................"
      echo "=============SUCCESS============"
      echo "DUO SECURITY URL REGISTRATION..."
      /usr/sbin/login_duo
      echo "SSH Server port changed to:" $port
      echo "Register your account with Duo security, and restart the ssh server (service ssh restart)"
      exit
      fi
fi
