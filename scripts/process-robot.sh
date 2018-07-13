#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "$0 <output.xml> <job> <build>"
    exit 1
fi
ROBOT_OUTPUT=$1
JOB=$2
BUILD=$3

TMP_XML=$(mktemp --suffix=.xml output-XXXX --tmpdir)
xmlstarlet ed -d '//kw' -d '//timeout' -d '//tags' $ROBOT_OUTPUT | tr -d '\n' > $TMP_XML
TIMESTR=$(xmlstarlet sel -t -v "/robot/@generated" $TMP_XML)
TIME=$(date -d "${TIMESTR}Z" +%s%N)

# test
xmlstarlet sel -t -m "//test" -c "." -n $TMP_XML | while read test; do
    NAME=$(echo "$test" | xmlstarlet sel -t -v "/test/@name" | tr ' ' '_' | xmlstarlet unesc)
    if [ "PASS" = $(echo "$test" | xmlstarlet sel -t -v "/test/status/@status" ) ]; then
        PASS=true
    else
        PASS=false
    fi
    echo insert test,job=$JOB,name=$NAME build=$BUILD,pass=$PASS $TIME
done

# suite
xmlstarlet sel -t -m "/robot/statistics/suite/stat" -c "." -n $TMP_XML | while read suite; do
    NAME=$(echo "$suite" | xmlstarlet sel -t -m "/stat" -v . | tr ' ' '_' | xmlstarlet unesc)
    PASS=$(echo "$suite" | xmlstarlet sel -t -v "/stat/@pass" )
    FAIL=$(echo "$suite" | xmlstarlet sel -t -v "/stat/@fail" )
    echo insert suite,job=$JOB,name=$NAME build=$BUILD,pass=$PASS,fail=$FAIL $TIME
done

# tag
xmlstarlet sel -t -m "/robot/statistics/tag/stat" -c "." -n $TMP_XML | while read tag; do
    NAME=$(echo "$tag" | xmlstarlet sel -t -m "/stat" -v . | tr ' ' '_' | xmlstarlet unesc)
    PASS=$(echo "$tag" | xmlstarlet sel -t -v "/stat/@pass" )
    FAIL=$(echo "$tag" | xmlstarlet sel -t -v "/stat/@fail" )
    echo insert tag,job=$JOB,name=$NAME build=$BUILD,pass=$PASS,fail=$FAIL $TIME
done
