#! /usr/bin/env sh

DEST=${AWS_S3_MOUNT:-/opt/s3fs/bucket}
. trap.sh

tail -f /dev/null
