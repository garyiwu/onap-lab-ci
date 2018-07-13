#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "$0 <output.xml>"
    exit 1
fi
ROBOT_OUTPUT=$1

#TMP_XML=$(mktemp --suffix=.xml)
#xmlstarlet ed -d '//kw' -d '//tags' -d '//timeout' $ROBOT_OUTPUT | tr -d '\n' > $TMP_XML
TIMESTR=$(xmlstarlet sel -t -v "/robot/@generated" /dev/shm/92/robot-plugin/o2.xml)
TIME=$(date -d "${TIMESTR}Z" +%s%N)
xmlstarlet sel -t -m "//test" -c "." -n /dev/shm/92/robot-plugin/o3.xml | while read test; do
    NAME=$(echo "$test" | xmlstarlet sel -t -v "/test/@name" | tr ' ' '_' | xmlstarlet unesc)
    if [ "PASS" = $(echo "$test" | xmlstarlet sel -t -v "/test/status/@status" ) ]; then
        PASS=t
    else
        PASS=f
    fi
    echo insert test,name=$NAME pass=$PASS $TIME
done
