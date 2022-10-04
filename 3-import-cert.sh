#!/bin/bash

# IMPORT: Basic Script to import SSL certificate for Conjur Leader (Master) Server

# Global Variables
hostDir="/home/user01/ConjurLabs/certs"
certDir="/opt/cyberark/conjur/certificates"
containerName="conjur"

# Copy SSL certificates to Conjur Leader (Master) Server
sudo cp $hostDir/*.cer $certDir/
sudo cp $hostDir/*.key $certDir/
docker exec $containerName mkdir -p $certDir
sudo docker cp $certDir/cacert.cer $containerName:$certDir/cacert.cer
sudo docker cp $certDir/conjur-leader.cer $containerName:$certDir/conjur-leader.cer
sudo docker cp $certDir/conjur-leader.key $containerName:$certDir/conjur-leader.key
sudo docker cp $certDir/conjur-follower.cer $containerName:$certDir/conjur-follower.cer
sudo docker cp $certDir/conjur-follower.key $containerName:$certDir/conjur-follower.key

# Import SSL certificates to Conjur Leader (Master) Server
docker exec $containerName evoke ca import --no-restart --force --root $certDir/cacert.cer
docker exec $containerName evoke ca import --no-restart --key $certDir/conjur-leader.key --set $certDir/conjur-leader.cer
docker exec $containerName evoke ca import --no-restart --key $certDir/conjur-follower.key $certDir/conjur-follower.cer

# Restart Conjur Services
docker exec $containerName sv restart conjur nginx pg seed
