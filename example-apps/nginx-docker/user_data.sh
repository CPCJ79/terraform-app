#!/bin/bash -xe
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

set -e

# docker run \
#     --name <my_docker> \
#     -p 8080:8080 \
#     --pull always
#     --log-driver syslog --log-opt syslog-address=tcp://log-collector.saws1.us-west-2.dev.23andme.net:5140 \
#     docker.artifactory.local.23andme.net/23andme/saws/nginx-docker:latest
