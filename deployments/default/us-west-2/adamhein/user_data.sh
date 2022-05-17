#!/bin/bash -xe
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

set -e

export AWS_DEFAULT_REGION=us-west-2

useradd -m valheim
sudo yum install -y glibc.i686 libstdc++.i686 SDL2 amazon-efs-utils --setopt=protected_multilib=false 

cd /home/valheim/
mkdir -p /home/valheim/.config/
sudo mount -t efs -o tls,accesspoint=fsap-0014c62c2787ea364,iam fs-019858fed90b4c23f:/ /home/valheim/.config

mkdir -p valheim-server/ 
curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
chown -R valheim:valheim /home/valheim/

sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1

systemctl restart network.service

sudo su valheim

linux64 /home/valheim/steamcmd.sh +force_install_dir valheim-server/ +login anonymous +app_update 896660 validate +quit

export HOME=/home/valheim
export SteamAppId=892970
export templdpath=$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=./linux64:$LD_LIBRARY_PATH


/home/valheim/valheim-server/valheim_server.x86_64 -name "valheim" -port 2456 -world "valheim" -password "butts" -batchmode -nographics -public 1

export LD_LIBRARY_PATH=$templdpath
