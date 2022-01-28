#!/bin/bash -xe
#exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1


# set -e

# export AWS_DEFAULT_REGION=us-west-2

curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_osx.tar.gz" | tar zxvf -
./steamcmd +force_install_dir . +login anonymous +app_update 108600 +quit
