#!/bin/bash
# the server tries to connect to another machine through ssh
# if it fails, it then restarts the interface and tries one more time..
# if it fails on a second attempt, then it will wait for some time before going back to the begining

# perhaps these should be set on environment variables
# $1 should be the sleeping time in minutes
# $2 host
# $3 username
# $4 key path
# $5 port
# $6 interface
main() {
    SLEEPING_TIME=$1;
    try_to_connect "$2" "$3" "$4" "$5"; # first attempt
    if [[ $? -ne 0 ]]
    then
        # did not connect on the first attempt
        echo "$(date): (ssh) #first-attempt failed" >> log;
        check_cooldown /tmp/script-lock $(($SLEEPING_TIME*60));
        time_left=$?;
        if [[ $time_left -eq 0 ]] # restarts the interface and retry
        then
            echo "OPA aqui foi $6";
            restart_interface "$6";
            echo "foi?";
            sleep 5;
            try_to_connect "$2" "$3" "$4" "$5";
            if [[ $? -ne 0 ]] # if it failed again, the lock should be activated.
            then
                echo "$(date): (ssh) #second-attempt failed" >> log;
                lock; #lock
                exit 0;
            else # it connected on the second attempt, the lock should be released.
                echo "$(date): (ssh) #second-attempt success" >> log;
                unlock;
                exit 0;

            fi
        fi
    else
        # ok, it connected on the first attempt remove any possible locks
        echo "$(date): (ssh) #first-attempt success" >> log;
        unlock;
        exit 0;
    fi
}

lock() {
    touch /tmp/script-lock;
}

unlock() {
    rm -f /tmp/script-lock;
}

# this function should check if the cooldown has finished
# $1 should be the file
# $2 should be the cooldown in minutes
check_cooldown() {
    if [ -a $1 ]
    then
        time_elapsed=$(expr $(date +%s) - $(date +%s -r $1));
        time_left=$(expr $(($2*60)) - $time_elapsed);
        if [ $time_elapsed -gt $(($2*60)) ] # if the file os older than $2 * 60 seconds
        then
            rm $1; # removes the file and the cooldown.
            echo "$(date): lock removed" >> log;
            return 0;
        else
            echo "$(date): lock still active" >> log;
            exit 0; # the lock is active, the script should exit.
        fi
    fi
    return 0;
}

# $1 should be the host
# $2 username
# $3 the key path
# $4 port
try_to_connect() {
    server_host="$1";
    username="$2";
    key_path="$3";
    port="$4";
    ssh -i "$key_path" -p "$port" $username@$server_host "exit" 2> errors;
    return $result
}

# $1 should be the interface
restart_interface() {
    iface=$1;
    ifdown "$iface";
    ifup "$iface";
    echo "$(date): restarted interface" >> log;
}
