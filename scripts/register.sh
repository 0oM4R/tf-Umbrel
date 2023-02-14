#!/bin/bash
set -eox pipefai
while curl http://10.21.21.4:3006 ; [ $? -eq 7 ];do
    echo manager not ready;
   sleep 20; 
  done
curl -v -X POST  http://10.21.21.4:3006/v1/account/register -H "Content-Type: application/json" -d '{"name": "${USERNAME}", "password": "${PASSWORD}"}'