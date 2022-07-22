#! /usr/bin/env sh

PERIOD=${1:-60}
AWS_S3_MOUNT=${AWS_S3_MOUNT:-/opt/s3fs/bucket}

if [ "$UID" -gt 0 ]; then
    RUN_AS=$UID
fi

# shellcheck disable=SC1091
. trap.sh

while true; do
    su - $RUN_AS -c "ls $AWS_S3_MOUNT"
    sleep "$PERIOD"
done
