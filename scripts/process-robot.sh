#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "$0 <output.xml> <job> <build>"
    exit 1
fi
ROBOT_OUTPUT=$1
JOB=$2
BUILD=$3

INFLUX_ENDPOINT='http://10.145.123.20:8086/write?db=robot'

TMP_XML=/tmp/output-$JOB-$BUILD.xml
xmlstarlet ed -d '//kw' -d '//timeout' -d '//tags' $ROBOT_OUTPUT | tr -d '\n' > $TMP_XML

# Canonicalize Robot suite names
sed -i 's/ONAP Verify/ONAP CI/g' $TMP_XML
sed -i 's/ONAP Daily/ONAP CI/g' $TMP_XML
sed -i 's/OpenECOMP ETE/ONAP CI/g' $TMP_XML

TIMESTR=$(xmlstarlet sel -t -v "/robot/@generated" $TMP_XML)
TIME=$(date -d "${TIMESTR}Z" +%s%N)

POINTS_FILE=/tmp/points-$JOB-$BUILD.txt

# test
xmlstarlet sel -t -m "//test" -c "." -n $TMP_XML | while read test; do
    NAME=$(echo "$test" | xmlstarlet sel -t -v "/test/@name" | tr ' ' '_' | xmlstarlet unesc)
    if [ "PASS" = $(echo "$test" | xmlstarlet sel -t -v "/test/status/@status" ) ]; then
        PASS=true
    else
        PASS=false
    fi
    STARTTIME=$(date -d "$(echo $test | xmlstarlet sel -t -v "/test/status/@starttime")Z" +%s%N)
    ENDTIME=$(date -d "$(echo $test | xmlstarlet sel -t -v "/test/status/@endtime")Z" +%s%N)
    echo test,job=$JOB,name=$NAME build=$BUILD,pass=$PASS,starttime=$STARTTIME,endtime=$ENDTIME $TIME | tee -a $POINTS_FILE
done

# suite
xmlstarlet sel -t -m "/robot/statistics/suite/stat" -c "." -n $TMP_XML | while read suite; do
    NAME=$(echo "$suite" | xmlstarlet sel -t -m "/stat" -v . | tr ' ' '_' | xmlstarlet unesc)
    PASS=$(echo "$suite" | xmlstarlet sel -t -v "/stat/@pass" )
    FAIL=$(echo "$suite" | xmlstarlet sel -t -v "/stat/@fail" )
    echo suite,job=$JOB,name=$NAME build=$BUILD,pass=$PASS,fail=$FAIL $TIME | tee -a $POINTS_FILE
done

# tag
xmlstarlet sel -t -m "/robot/statistics/tag/stat" -c "." -n $TMP_XML | while read tag; do
    NAME=$(echo "$tag" | xmlstarlet sel -t -m "/stat" -v . | tr ' ' '_' | xmlstarlet unesc)
    PASS=$(echo "$tag" | xmlstarlet sel -t -v "/stat/@pass" )
    FAIL=$(echo "$tag" | xmlstarlet sel -t -v "/stat/@fail" )
    echo tag,job=$JOB,name=$NAME build=$BUILD,pass=$PASS,fail=$FAIL $TIME | tee -a $POINTS_FILE
done

curl -i $INFLUX_ENDPOINT --data-binary @$POINTS_FILE
