#!/bin/bash


# $1 should be the host
# $2 username
# $3 the key path
# $4 port
try_to_connect() {
    server_host=$1;
    username=$2
    key_path=$3;
    port=$4;

    ssh -i $key_path -p $port $username@$server_host exit;
    return $?
}
