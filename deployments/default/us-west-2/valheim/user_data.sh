#!/bin/bash -xe
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

set -e

export AWS_DEFAULT_REGION=us-west-2

useradd -m valheim

sudo yum install -y glibc.i686 libstdc++.i686
sudo su valheim

cd /home/valheim/
mkdir -p valheim-server/ curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
/home/valheim/steamcmd.sh +login anonymous +force_install_dir valheim-server/ +app_update 896660 validate +quit

export SteamAppId=892970
export SERVER_PASSWORD=(aws ssm get-parameter --name /app/valheim/world_password --with-decryption --query "Parameter.Value" --output text)
export WORLD_NAME=(aws ssm get-parameter --name /app/valheim/world_name --with-decryption --query "Parameter.Value" --output text)
export SERVER_NAME="FrankenHeim"

if [ ! -f "/home/valheim/.config/unity3d/IronGate/Valheim/worlds/${WORLD_NAME}.fwl" ]; then
    echo "No world files found locally, Starting Fresh"
    fi

./valheim_server.x86_64 -name "Frankheim" -port 2456 -world $WORLD_NAME -password $SERVER_PASSWORD -batchmode -nographics -public 1

export LD_LIBRARY_PATH=$templdpath

