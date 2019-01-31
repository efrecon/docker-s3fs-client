#! /usr/bin/env sh

DEST=${AWS_S3_MOUNT:-/mnt/bucket}
. trap.sh

tail -f /dev/null