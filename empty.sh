#! /usr/bin/env sh

AWS_S3_MOUNT=${AWS_S3_MOUNT:-/opt/s3fs/bucket}
# shellcheck disable=SC1091
. trap.sh

tail -f /dev/null
