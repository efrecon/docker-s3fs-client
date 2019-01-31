#! /usr/bin/env sh

PERIOD=${1:-60}
DEST=${AWS_S3_MOUNT:-/mnt/bucket}

. trap.sh

while true; do
    ls $DEST
    sleep $PERIOD
done
