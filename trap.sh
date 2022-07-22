#!/bin/sh

exit_script() {
    SIGNAL=$1
    echo "Caught $SIGNAL! Unmounting ${AWS_S3_MOUNT}..."
    fusermount -uz "${AWS_S3_MOUNT}"
    # shellcheck disable=SC2009
    s3fs=$(ps -o pid= -o comm= | grep s3fs | sed -E 's/\s*(\d+)\s+.*/\1/g')
    if [ -n "$s3fs" ]; then
        echo "Forwarding $SIGNAL to $s3fs"
        kill -"$SIGNAL" "$s3fs"
    fi
    trap - "$SIGNAL" # clear the trap
    exit $?
}

trap "exit_script INT" INT
trap "exit_script TERM" TERM
