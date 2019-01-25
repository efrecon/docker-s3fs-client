#! /usr/bin/env sh

# Where are we going to mount the remote bucket resource in our container.
DEST=${AWS_S3_MOUNT:-/mnt/bucket}

# Check variables and defaults
if [ -z "${AWS_S3_ACCESS_KEY_ID}" -a -z "${AWS_S3_SECRET_ACCESS_KEY}" -a -z "${AWS_S3_SECRET_ACCESS_KEY_FILE}" -a -z "${AWS_S3_AUTHFILE}" ]; then
    echo "You need to provide some credentials!!"
    exit
fi
if [ -z "${AWS_S3_BUCKET}" ]; then
    echo "No bucket name provided!"
    exit
fi
if [ -z "${AWS_S3_URL}" ]; then
    AWS_S3_URL="https://s3.amazonaws.com"
fi

if [ -n "${AWS_S3_SECRET_ACCESS_KEY_FILE}" ]; then
    AWS_S3_SECRET_ACCESS_KEY=$(read ${AWS_S3_SECRET_ACCESS_KEY_FILE})
fi

# Create or use authorisation file
if [ -z "${AWS_S3_AUTHFILE}" ]; then
    AWS_S3_AUTHFILE=/etc/passwd-s3fs
    echo "${AWS_S3_ACCESS_KEY_ID}:${AWS_S3_SECRET_ACCESS_KEY}" > ${AWS_S3_AUTHFILE}
    chmod 600 ${AWS_S3_AUTHFILE}
fi

# forget about the password once done (this will have proper effects when the
# PASSWORD_FILE-version of the setting is used)
if [ -n "${AWS_S3_SECRET_ACCESS_KEY}" ]; then
    unset AWS_S3_SECRET_ACCESS_KEY
fi

# Create destination directory if it does not exist.
if [ ! -d $DEST ]; then
    mkdir -p $DEST
fi

# Deal with ownership
if [ $OWNER -gt 0 ]; then
    adduser -u $OWNER -HD -G users s3fs
    chown s3fs $AWS_S3_MOUNT
    chown s3fs ${AWS_S3_AUTHFILE}
fi

# Debug options
DEBUG_OPTS=
if [ $S3FS_DEBUG = "1" ]; then
    DEBUG_OPTS="-d -d"
fi

# Mount and verify that something is present. davfs2 always creates a lost+found
# sub-directory, so we can use the presence of some file/dir as a marker to
# detect that mounting was a success. Execute the command on success.
s3fs $DEBUG_OPTS ${S3FS_ARGS} -o passwd_file=${AWS_S3_AUTHFILE} -o url=${AWS_S3_URL} -o uid=$OWNER ${AWS_S3_BUCKET} ${AWS_S3_MOUNT}
mounted=$(mount | grep s3fs | grep "${AWS_S3_MOUNT}")
if [ -n "${mounted}" ]; then
    echo "Mounted bucket ${AWS_S3_BUCKET} onto ${AWS_S3_MOUNT}"
    exec "$@"
else
    echo "Mount failure"
fi