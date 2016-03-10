#!/bin/bash


# this function should check if the cooldown has finished
# $1 should be the file
# $2 should be the cooldown in minutes
check_cooldown() {
    if [ -a $1 ]
    then
        echo "arquivo existe";
        time_elapsed=$(expr $(date +%s) - $(date +%s -r abc));
        echo $time_elapsed;
        if [ $time_elapsed -gt $(($2*60)) ] # if the file os older than $2 * 60 seconds 
        then
            rm $1; # removes the file and the cooldown.
            return 0;
        else
            return -1;
        fi
    fi
    return 0;
}

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

# $1 should be the interface
restart_interface() {
    iface=$1;
    debug_log ifdown $iface;
    debug_log ifup $iface;
}

# This will output errors to a file called errors
# $1 the command
debug_log() {
    $1 2> tmp; # runs the command and gets the errors to stdout
    while read line ; do # reads stdout
        echo "$(date): $(caller 0)" >> errors; # echoes the output to a file
    done < tmp

    if [[ $(wc -l <tmp) -ge 1 ]]
    then
        echo "There's been an error getting the interface down";
        echo "Check the error logfile";
        exit;
    else
        rm tmp;
        return 0;
    fi
}
