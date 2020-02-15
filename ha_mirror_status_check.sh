#!/bin/bash

function write_border () {
        echo "----------------"
}

function reboot_blade_1 () {
        echo "resetting blade 1...." >> $1
        # K98142338, I think bladectl command may be better to simulate re-seating the blade
        echo "bladectl -b 1 -r" >> $1
        bladectl -b 1 -r
        # K11333
        # echo "clsh --slot=1 reboot" >> $1
        # clsh --slot=1 reboot  
}

function wait_seconds () {
        sleep 20
}

function wait_until_blade_is_ready () {
        # Wait until 2 blades are running for 40 seconds.
        num=0

        while true
        do
                num_of_running_blade=`tmsh show sys cluster | egrep "Run$" | wc -l`
                if [ $num_of_running_blade -eq 2 ]
                then
                        let num++
                        write_border >> $1
                        date >> $1
                        echo "2 blades are running..." >> $1
                else
                        num=0
                        write_border >> $1
                        date >> $1
                        echo "Waiting for blade 1..." >> $1
                fi

                if [ $num -ge 3 ]
                then
                        return
                fi
                wait_seconds
        done
}

function wait_until_tmm_is_ready () {
        # Wait until all TMMs are running for 20 seconds.

        num=0
        while true
        do
                num_of_running_tmm=`tmsh show sys tmm-info | grep Sys::TMM | wc -l`
                if [ $num_of_running_tmm -eq 48 ]
                then
                        let num++
                        write_border >> $1
                        date >> $1
                        echo "48 TMMs are running..." >> $1
                else
                        num=0
                        write_border >> $1
                        date >> $1
                        echo "$num_of_running_tmm TMMs are running..." >> $1
                fi

                if [ $num -ge 2 ]
                then
                        return
                fi
                wait_seconds
        done               
}

function check_num_of_connected () {
        # When all of the HA Mirror Status table for 40 seconds, the blade 1 is rebooted.

        num=0
        while true
        do
                write_border >> $1
                date >> $1
                tmsh show sys ha-mirror >> $1
                num_of_connected=`tmsh show sys ha-mirror | grep connected | wc -l`

                if [ $num_of_connected -eq 48 ]
                then
                        let num++
                        echo "Number of connected in HA Mirror Status table is $num_of_connected." >> $1
                else
                        num=0
                        echo "Number of connected in HA Mirror Status table is $num_of_connected." >> $1
                        # !!! If the issue is reproduced, the script should be looping here.
                fi

                if [ $num -ge 3 ]
                then
                        reboot_blade_1 $1
                        wait_seconds
                        return
                fi
                wait_seconds
        done
}

log_file="/root/ha-mirror.log"

while true
do
        wait_until_blade_is_ready $log_file
        wait_until_tmm_is_ready $log_file
        check_num_of_connected $log_file
done
