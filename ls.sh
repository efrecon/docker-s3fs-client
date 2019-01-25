#! /usr/bin/env sh

PERIOD=${1:-60}
DEST=${AWS_S3_MOUNT:-/mnt/bucket}

exit_script() {
    echo "Unmounting ${DEST}"
    fusermount -uz ${DEST}
    trap - SIGINT SIGTERM # clear the trap
    exit $?
}

trap exit_script SIGINT SIGTERM

while true; do
    ls $DEST
    sleep $PERIOD
done
