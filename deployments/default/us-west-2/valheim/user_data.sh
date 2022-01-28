#!/bin/bash -xe
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

set -e

export AWS_DEFAULT_REGION=us-west-2

curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_osx.tar.gz" | tar zxvf -
./steamcmd +force_install_dir . +login anonymous +app_update 892970 +quit

export templdpath=$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=./linux64:$LD_LIBRARY_PATH
export SteamAppId=892970
export SERVER_PASSWORD=(aws ssm get-parameter --name /app/valheim/world_password --with-decryption --query "Parameter.Value" --output text)
export WORLD_NAME=(aws ssm get-parameter --name /app/valheim/world_name --with-decryption --query "Parameter.Value" --output text)

echo "Checking if world files exist locally"



if [ ! -f "/home/${username}/.config/unity3d/IronGate/Valheim/worlds/${world_name}.fwl" ]; then
    echo "No world files found locally, checking if backups exist"
    BACKUPS=$(aws s3api head-object --bucket ${bucket} --key "${world_name}.fwl" || true > /dev/null 2>&1)
    if [ -z "$${BACKUPS}" ]; then 
        echo "No backups found using world name \"${world_name}\". A new world will be created."
    else 
        echo "Backups found, restoring..."
        aws s3 cp "s3://${bucket}/${world_name}.fwl" "/home/${username}/.config/unity3d/IronGate/Valheim/worlds/${world_name}.fwl"
        aws s3 cp "s3://${bucket}/${world_name}.db" "/home/${username}/.config/unity3d/IronGate/Valheim/worlds/${world_name}.db"
    fi
fi

ls -lahtr /home/${username}/.config/unity3d/IronGate/Valheim/adminlist.txt

echo "Starting server PRESS CTRL-C to exit"

./valheim_server.x86_64 -name "${server_name}" -port 2456 -world $WORLD_NAME -password $SERVER_PASSWORD -batchmode -nographics -public 1

export LD_LIBRARY_PATH=$templdpath

