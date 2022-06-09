#! /usr/bin/env sh

PERIOD=${1:-60}
DEST=${AWS_S3_MOUNT:-/opt/s3fs/bucket}

if [ $UID -gt 0 ]; then
    RUN_AS=$UID
fi

. trap.sh

while true; do
    su - $RUN_AS -c "ls $DEST"
    sleep $PERIOD
done
