#!/bin/bash

check_uid () {
   if [[ $EUID -ne 0 ]]; then
       echo "This script must be run as root"
       exit 1
   fi
}

check_os () {
    if [ ! -f /etc/redhat-release ]; then
        echo "This script works only on RedHat/Centos OS"
        exit 1
    fi
}

main () {
    echo "Fixing permissions, this will take a while.."
    for PACKAGE in $(rpm -qa); do
        rpm --setugids $PACKAGE 2>/dev/null
        rpm --setperms $PACKAGE 2>/dev/null
        echo "Done"
    done
}

check_uid
check_os
main
