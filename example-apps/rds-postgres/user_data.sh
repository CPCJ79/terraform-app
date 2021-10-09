#!/bin/bash -xe
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

set -e

# export AWS_DEFAULT_REGION=us-west-2

# export DB_USERNAME=$(aws ssm get-parameter --name /app/<app-name>/db_username --with-decryption --query Parameter.Value --output text)
# export DB_PASSWORD=$(aws ssm get-parameter --name /app/<app-name>/db_password --with-decryption --query Parameter.Value --output text)

# docker run \
#     --name <my_docker> \
#     -p 8080:8080 \
#     -e SHORT_DOMAIN_HOST=<url> \
#     -e SHORT_DOMAIN_SCHEMA=http \
#     -e DB_DRIVER=postgres \
#     -e DB_USER \
#     -e DB_PASSWORD \
#     -e DB_HOST=<db_name> \
#     --log-driver syslog --log-opt syslog-address=tcp://log-collector.saws1.us-west-2.dev.23andme.net:5140 \
#     --pull always \
#     docker/docker.io:latest
