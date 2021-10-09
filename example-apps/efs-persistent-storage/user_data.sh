#!/bin/bash -xe
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1


# set -e

# export AWS_DEFAULT_REGION=us-west-2

# export EXAMPLE_SECRET=$(aws ssm get-parameter --name /app/<app-name>/example_secret --with-decryption --query Parameter.Value --output text)
# export RANDOM_USERNAME=$(aws ssm get-parameter --name /app/<app-name>/random_username --with-decryption --query Parameter.Value --output text)

# docker run \
#     --name my_docker \
#     -p 8000:80 \
#     -e EXAMPLE_SECRET \
#     -e RANDOM_USERNAME \
#     --log-driver syslog --log-opt syslog-address=tcp://log-collector.saws1.us-west-2.dev.23andme.net:5140 \
#     --pull always \
#     docker/docker.io:latest
