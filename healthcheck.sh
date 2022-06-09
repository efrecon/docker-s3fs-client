#!/bin/sh

set -eu

# Where are we going to mount the remote bucket resource in our container.
DEST=${AWS_S3_MOUNT:-/opt/s3fs/bucket}

# Test if there is still a fuse.s3fs mount onto the destination mountpoint. We
# use /proc/mounts because it contains fresh information, always.
grep fuse.s3fs /proc/mounts | grep -q "${DEST}" || exit 1
