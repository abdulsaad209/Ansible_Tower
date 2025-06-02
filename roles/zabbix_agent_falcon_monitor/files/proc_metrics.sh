#!/bin/bash

proc_name=$1
metric=$2

pid=$(pgrep -f "$proc_name" | head -n1)
if [ -z "$pid" ]; then
    echo 0
    exit 0
fi

case "$metric" in
    status)
        echo 1
        ;;
    cpu)
        ps -p "$pid" -o %cpu= | xargs
        ;;
    mem)
        ps -p "$pid" -o %mem= | xargs
        ;;
    rss)
        ps -p "$pid" -o rss= | awk '{ printf "%.2f", $1 / 1024 }'
        ;;
    vsz)
        ps -p "$pid" -o vsz= | awk '{ printf "%.2f", $1 / 1024 }'
        ;;
    uptime)
        ps -p "$pid" -o etimes= | xargs
        ;;
    *)
        echo "Invalid metric"
        exit 1
        ;;
esac
