#!/bin/bash

LD_LIBRARY_PATH=$(pwd) apps/openssl speed

for i in sm3 sm4 aes-128-gcm aes-192-gcm aes-256-gcm; do
    LD_LIBRARY_PATH="$(pwd)" apps/openssl speed -evp $i
done
