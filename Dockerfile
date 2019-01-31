FROM alpine:3.8

ARG S3FS_VERSION=v1.84

# Specify URL and secrets. When using AWS_S3_SECRET_ACCESS_KEY_FILE, the secret
# key will be read from that file itself, which helps passing further passwords
# using Docker secrets. You can either specify the path to an authorisation
# file, set environment variables with the key and the secret.
ENV AWS_S3_URL=https://s3.amazonaws.com
ENV AWS_S3_ACCESS_KEY_ID=
ENV AWS_S3_SECRET_ACCESS_KEY=
ENV AWS_S3_SECRET_ACCESS_KEY_FILE=
ENV AWS_S3_AUTHFILE=
ENV AWS_S3_BUCKET=

# User ID of share owner
ENV OWNER=0

# Location of directory where to mount the drive into the container.
ENV AWS_S3_MOUNT=/mnt/bucket

# s3fs tuning
ENV S3FS_DEBUG=0
ENV S3FS_ARGS=

RUN apk --no-cache add ca-certificates fuse build-base git automake autoconf alpine-sdk libxml2 libxml2-dev libressl-dev fuse-dev libcurl curl-dev tini && \
    git clone https://github.com/s3fs-fuse/s3fs-fuse.git && \
    cd s3fs-fuse && \
    git checkout tags/${S3FS_VERSION} && \
    ./autogen.sh && \
    ./configure --prefix=/usr && \
    make && \
    make install && \
    apk --no-cache del automake autoconf libxml2-dev libressl-dev fuse-dev curl-dev

# Test compile
RUN s3fs --version

COPY *.sh /usr/local/bin/

# Following should match the WEBDRIVE_MOUNT environment variable.
VOLUME [ "/mnt/bucket" ]

# The default is to perform all system-level mounting as part of the entrypoint
# to then have a command that will keep listing the files under the main share.
# Listing the files will keep the share active and avoid that the remote server
# closes the connection.
ENTRYPOINT [ "tini", "-g", "--", "docker-entrypoint.sh" ]
CMD [ "ls.sh" ]