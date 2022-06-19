#!/bin/bash -xe
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

set -e

export AWS_DEFAULT_REGION=us-east-2
export DB_PASSWORD=$(aws ssm get-parameter --name /app/frising/world_password --with-decryption --query Parameter.Value --output text)
export EFS_ACCESS_POINT_ID=$(aws ssm get-parameter --name /app/frising/efs_access_point --query Parameter.Value --output text)
export EFS_FILESYSTEM_POINT_ID=$(aws ssm get-parameter --name /app/frising/efs_fs_id --query Parameter.Value --output text)

useradd -m vrising
sudo yum -y docker

systemctl start docker

cd /home/vrising/
mkdir -p /home/vrising/persistentdata
sudo mount -t efs -o tls,accesspoint=${EFS_ACCESS_POINT_ID},iam ${EFS_FILESYSTEM_POINT_ID}:/ /home/vrising/persistentdata

chown -R vrising:vrising /home/vrising/

sudo su vrising

export HOME=/home/vrising
export SteamAppId=1829350
export templdpath=$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=./linux64:$LD_LIBRARY_PATH

docker run -d --name='vrising' \
--net='bridge' \
-e TZ="America/New_York" \
-e SERVERNAME="frising" \
-v '/home/vrising':'/mnt/vrising/server':'rw' \
-v '/home/vrising/persistentdata':'/mnt/vrising/persistentdata':'rw' \
-p 9876:9876/udp \
-p 9877:9877/udp \
'trueosiris/vrising'

