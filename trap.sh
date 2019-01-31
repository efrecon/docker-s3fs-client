exit_script() {
    SIGNAL=$1
    echo "Caught $SIGNAL! Unmounting ${DEST}..."
    fusermount -uz ${DEST}
    s3fs=$(ps -o pid= -o comm= | grep s3fs | sed -E 's/\s*(\d+)\s+.*/\1/g')
    if [ -n "$s3fs" ]; then
        echo "Forwarding $SIGNAL to $s3fs"
        kill -$SIGNAL $s3fs
    fi
    trap - $SIGNAL # clear the trap
    exit $?
}

trap "exit_script INT" INT
trap "exit_script TERM" TERM
