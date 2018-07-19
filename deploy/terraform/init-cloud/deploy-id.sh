#!/bin/bash

if [[ $(git rev-parse --short HEAD >> /dev/null 2>&1; echo $?) == 0 ]]
then
    ID="C-$(git rev-parse --short HEAD)"
else
    ID="D-$(date +%s)"
fi

echo "$ID" > "$(pwd)/deploy-id"