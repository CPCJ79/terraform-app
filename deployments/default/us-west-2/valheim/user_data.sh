#!/bin/bash -xe
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

set -e

export AWS_DEFAULT_REGION=us-west-2

export DB_USER=$(aws ssm get-parameter --name /app/url-shorty/db_username --with-decryption --query Parameter.Value --output text)
export DB_PASSWORD=$(aws ssm get-parameter --name /app/url-shorty/db_password --with-decryption --query Parameter.Value --output text)
export GEOLITE_LICENSE_KEY=$(aws ssm get-parameter --name /app/url-shorty/db_license --with-decryption --query Parameter.Value --output text)
export DB_HOST=$(aws ssm get-parameter --name /app/url-shorty/db_host --with-decryption --query Parameter.Value --output text)

docker run \
    --name my_shlink \
    -p 8080:8080 \
    -e SHORT_DOMAIN_HOST=go.23andme.com \
    -e SHORT_DOMAIN_SCHEMA=http \
    -e GEOLITE_LICENSE_KEY=$GEOLITE_LICENSE_KEY \
    -e DISABLE_TRACKING=true \
    -e DISABLE_IP_TRACKING=true \
    -e DB_DRIVER=postgres \
    -e DB_USER=$DB_USER \
    -e DB_PASSWORD=$DB_PASSWORD \
    -e DB_HOST=$DB_HOST \
    --pull always \
    docker.artifactory.local.23andme.net/shlinkio/shlink
