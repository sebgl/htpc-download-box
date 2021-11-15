#!/bin/bash

echo "====== START REMOVING ED ======="
sudo rm -rf $EDP
echo "====== START DOWN ======="
docker-compose down
echo "====== SLEEP 45s ======="
sleep 45
echo "====== START UP ======="
docker-compose up -d
