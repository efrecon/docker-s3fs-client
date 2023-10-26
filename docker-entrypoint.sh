#!/bin/sh

# Failsafe: Stop on errors and unset variables.
set -eu

# Debug
S3FS_DEBUG=${S3FS_DEBUG:-"0"}

# Env file
AWS_S3_ENVFILE=${AWS_S3_ENVFILE:-""}

_verbose() {
  if [ "$S3FS_DEBUG" = "1" ]; then
    printf %s\\n "$1" >&2
  fi
}

_error() {
  printf %s\\n "$1" >&2
  exit 1
}

# Read the content of the environment file, i.e. a file used to set the value of
# all/some variables.
if [ -n "$AWS_S3_ENVFILE" ]; then
    # Read and export lines that set variables in all-caps and starting with
    # S3FS_ or AWS_ from the configuration file. This is a security measure to
    # crudly protect against evaluating some evil code (but it will still
    # evaluate code as part of the value, so use it with care!)
    _verbose "Reading configuration from $AWS_S3_ENVFILE"
    while IFS= read -r line; do
        eval export "$line"
    done <<EOF
$(grep -E '^(S3FS|AWS_S3)_[A-Z_]+=' "$AWS_S3_ENVFILE")
EOF
fi

# S3 main URL
AWS_S3_URL=${AWS_S3_URL:-"https://s3.amazonaws.com"}

# Root directory for settings and bucket.
AWS_S3_ROOTDIR=${AWS_S3_ROOTDIR:-"/opt/s3fs"}

# Where are we going to mount the remote bucket resource in our container.
AWS_S3_MOUNT=${AWS_S3_MOUNT:-"${AWS_S3_ROOTDIR%/}/bucket"}

# Authorisation details
AWS_S3_ACCESS_KEY_ID=${AWS_S3_ACCESS_KEY_ID:-""}
AWS_S3_SECRET_ACCESS_KEY=${AWS_S3_SECRET_ACCESS_KEY:-""}
AWS_S3_SECRET_ACCESS_KEY_FILE=${AWS_S3_SECRET_ACCESS_KEY_FILE:-""}
AWS_S3_AUTHFILE=${AWS_S3_AUTHFILE:-""}

# Check variables and defaults
if [ -z "$AWS_S3_ACCESS_KEY_ID" ] && \
    [ -z "$AWS_S3_SECRET_ACCESS_KEY" ] && \
    [ -z "$AWS_S3_SECRET_ACCESS_KEY_FILE" ] && \
    [ -z "$AWS_S3_AUTHFILE" ]; then
    _error "You need to provide some credentials!!"
fi
if [ -z "${AWS_S3_BUCKET}" ]; then
    _error "No bucket name provided!"
fi

if [ -n "${AWS_S3_SECRET_ACCESS_KEY_FILE}" ]; then
    # shellcheck disable=SC2229   # We WANT to read the content of the file pointed by the variable!
    AWS_S3_SECRET_ACCESS_KEY=$(read -r "${AWS_S3_SECRET_ACCESS_KEY_FILE}")
fi

# Create or use authorisation file
if [ -z "${AWS_S3_AUTHFILE}" ]; then
    AWS_S3_AUTHFILE=${AWS_S3_ROOTDIR%/}/passwd-s3fs
    echo "${AWS_S3_ACCESS_KEY_ID}:${AWS_S3_SECRET_ACCESS_KEY}" > "${AWS_S3_AUTHFILE}"
    chmod 600 "${AWS_S3_AUTHFILE}"
fi

# forget about the password once done (this will have proper effects when the
# PASSWORD_FILE-version of the setting is used)
if [ -n "${AWS_S3_SECRET_ACCESS_KEY}" ]; then
    unset AWS_S3_SECRET_ACCESS_KEY
fi

# Create destination directory if it does not exist.
if [ ! -d "$AWS_S3_MOUNT" ]; then
    mkdir -p "$AWS_S3_MOUNT"
fi

# Add a group, default to naming it after the GID when not found
GROUP_NAME=$(getent group "$GID" | cut -d":" -f1)
if [ "$GID" -gt 0 ] && [ -z "$GROUP_NAME" ]; then
    _verbose "Add group $GID"
    addgroup -g "$GID" -S "$GID"
    GROUP_NAME=$GID
fi

# Add a user, default to naming it after the UID.
RUN_AS=${RUN_AS:-""}
if [ "$UID" -gt 0 ]; then
    USER_NAME=$(getent passwd "$UID" | cut -d":" -f1)
    if [ -z "$USER_NAME" ]; then
        _verbose "Add user $UID, turning on rootless-mode"
        adduser -u "$UID" -D -G "$GROUP_NAME" "$UID"
    else
        _verbose "Running as user $UID, turning on rootless-mode"
    fi
    RUN_AS=$UID
    chown "${UID}:${GID}" "$AWS_S3_MOUNT" "${AWS_S3_AUTHFILE}" "$AWS_S3_ROOTDIR"
fi

# Debug options
DEBUG_OPTS=
if [ "$S3FS_DEBUG" = "1" ]; then
    DEBUG_OPTS="-d -d"
fi

# Additional S3FS options
if [ -n "$S3FS_ARGS" ]; then
    S3FS_ARGS="-o $S3FS_ARGS"
fi

# Mount as the requested used.
_verbose "Mounting bucket ${AWS_S3_BUCKET} onto ${AWS_S3_MOUNT}, owner: $UID:$GID"
su - $RUN_AS -c "s3fs $DEBUG_OPTS ${S3FS_ARGS} \
    -o passwd_file=${AWS_S3_AUTHFILE} \
    -o "url=${AWS_S3_URL}" \
    -o uid=$UID \
    -o gid=$GID \
    ${AWS_S3_BUCKET} ${AWS_S3_MOUNT}"

# s3fs can claim to have a mount even though it didn't succeed. Doing an
# operation actually forces it to detect that and remove the mount.
su - $RUN_AS -c "touch ${AWS_S3_MOUNT}/.s3fs-test.txt && rm ${AWS_S3_MOUNT}/.s3fs-test.txt"

if healthcheck.sh; then
    echo "Mounted bucket ${AWS_S3_BUCKET} onto ${AWS_S3_MOUNT}"
    exec "$@"
else
    _error "Mount failure"
fi
