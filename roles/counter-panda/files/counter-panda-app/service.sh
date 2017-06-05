#!/bin/bash

#
# The following script starts and stops a service
# It is generic in the sense that it reads the service name and port from the json files
# For new services just hardlink to it, so changes in one place will affect all of its occurrences
#

# vars
action=$1							# action can be: start stop status restart
base_dir=`dirname $0`						
base_dir=`(cd $base_dir ; pwd)`
service=`cat $base_dir/package.json | grep -Pom 1 '"main": "\K[^"]*'`
port=`cat $base_dir/config.json | grep port | awk -F: '{ print $2 }'`
watchdog_interval=5

# return status of the service
function status_service()
{
        if netstat -anp | grep $port | grep -v TIME_WAIT > /dev/null; then
                echo "$service is up"
                return 0
        else
                echo "$service is down"
                return 1
        fi
}

# start the service
function start_service()
{
        if ! status_service > /dev/null; then
                echo "starting $service"
                cd $base_dir
                nohup nodejs $service > /var/log/$service.log 2>&1 &
                ret_val=$?
                cd - > /dev/null
                if [[ "$ret_val" == "0" ]]; then
                        echo  "$service started"
                else
                        echo "error starting $service"
                        exit 1
                fi
        else
                echo "$service is up"
        fi
}

# stop the service
function stop_service()
{
        if status_service > /dev/null; then
                echo "stopping $service"
                fuser -k $port/tcp > /dev/null 2>&1
                if [[ "$?" == "0" ]]; then
                        echo  "$service stopped"
                else
                        echo "error stopping $service"
                        exit 1
                fi
        else
                echo "$service is down"
        fi
}

# restarts the service
function restart_service()
{
        stop_service
	sleep 2
        start_service
}

# watchdog makes sure that service is always up
watchdog_service()
{
        while true; do
                if status_service > /dev/null; then
                        echo "watchdog: $service is up"
                else
                        echo "watchdog: starting $service"
                        start_service > /dev/null
                fi
                echo "watchdog: waiting $watchdog_interval seconds till next check"
                sleep $watchdog_interval
        done
}

case "$action" in
"start")
    start_service
    ;;
"stop")
    stop_service
    ;;
"status")
    status_service
    ;;
"restart")
    restart_service
    ;;
"watchdog")
    watchdog_service
    ;;
*)
    echo "usage: `basename $0` start|stop|status|restart"
    exit 1
    ;;
esac
