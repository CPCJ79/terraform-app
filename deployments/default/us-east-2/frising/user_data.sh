#!/bin/bash -xe
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

set -e

export AWS_DEFAULT_REGION=us-east-2
export DB_PASSWORD=$(aws ssm get-parameter --name /app/frising/world_password --with-decryption --query Parameter.Value --output text)
export EFS_ACCESS_POINT_ID=$(aws ssm get-parameter --name /app/frising/efs_access_point --query Parameter.Value --output text)
export EFS_FILESYSTEM_POINT_ID=$(aws ssm get-parameter --name /app/frising/efs_fs_id --query Parameter.Value --output text)

useradd -m vrising
sudo yum install -y glibc.i686 libstdc++.i686 SDL2 amazon-efs-utils --setopt=protected_multilib=false epel-release wine xorg-x11-server-Xvfb

cd /home/vrising/
mkdir -p /home/vrising/VRising
sudo mount -t efs -o tls,accesspoint=${EFS_ACCESS_POINT_ID},iam ${EFS_FILESYSTEM_POINT_ID}:/ /home/vrising/VRising

curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
chown -R vrising:vrising /home/vrising/

sudo su vrising

linux64 /home/vrising/steamcmd.sh +force_install_dir /home/vrising/ +login anonymous +app_update 1829350 validate +quit

export HOME=/home/vrising
export SteamAppId=1829350
export templdpath=$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=./linux64:$LD_LIBRARY_PATH
export WINEARCH=win64

mkdir -p save-data/Settings

/usr/bin/xvfb-run --auto-servernum --server-args='-screen 0 640x480x24:32' /usr/bin/wine VRisingServer.exe -persistentDataPath ./save-data -logFile server.log
