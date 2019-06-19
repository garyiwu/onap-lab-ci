#!/bin/bash
DIR=$(dirname "$(readlink -f "$0")")
JOB=$(basename $DIR)
echo $JOB
for POD_TO_DELETE in $(cat $DIR/pods_to_delete.txt); do
    echo build "$JOB $POD_TO_DELETE"
    java -jar ~/jenkins-cli.jar  -s http://localhost:8080/jenkins -auth jenkins:g2jenkins build $JOB -p POD_TO_DELETE=$POD_TO_DELETE
done
