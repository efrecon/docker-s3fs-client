ARG ALPINE_VERSION=3.15.6
FROM alpine:$ALPINE_VERSION AS build

ARG S3FS_VERSION=v1.91

RUN apk --no-cache add \
    ca-certificates \
    build-base \
    git \
    alpine-sdk \
    libcurl \
    automake \
    autoconf \
    libxml2-dev \
    libressl-dev \
    mailcap \
    fuse-dev \
    curl-dev && \
  git clone https://github.com/s3fs-fuse/s3fs-fuse.git && \
  cd s3fs-fuse && \
  git checkout tags/${S3FS_VERSION} && \
  ./autogen.sh && \
  ./configure --prefix=/usr && \
  make -j && \
  make install

FROM alpine:$ALPINE_VERSION

# Metadata
LABEL MAINTAINER=efrecon+github@gmail.com
LABEL org.opencontainers.image.title="efrecon/s3fs"
LABEL org.opencontainers.image.description="Mount S3 buckets from within a container and expose them to host/containers"
LABEL org.opencontainers.image.authors="Emmanuel Frécon <efrecon+github@gmail.com>"
LABEL org.opencontainers.image.url="https://github.com/efrecon/docker-s3fs-client"
LABEL org.opencontainers.image.documentation="https://github.com/efrecon/docker-s3fs-client/README.md"
LABEL org.opencontainers.image.source="https://github.com/efrecon/docker-s3fs-client/Dockerfile"

COPY --from=build /usr/bin/s3fs /usr/bin/s3fs

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

# User and group ID of S3 mount owner
ENV RUN_AS=
ENV UID=0
ENV GID=0

# Location of directory where to mount the drive into the container.
ENV AWS_S3_MOUNT=/opt/s3fs/bucket

# s3fs tuning
ENV S3FS_DEBUG=0
ENV S3FS_ARGS=

RUN mkdir /opt/s3fs && \
    apk --no-cache add \
      ca-certificates \
      mailcap \
      fuse \
      libxml2 \
      libcurl \
      libgcc \
      libstdc++ \
      tini && \
    deluser xfs && \
    s3fs --version

# allow access to volume by different user to enable UIDs other than root when
# using volumes
RUN echo user_allow_other >> /etc/fuse.conf

COPY *.sh /usr/local/bin/

WORKDIR /opt/s3fs

# Following should match the AWS_S3_MOUNT environment variable.
VOLUME [ "/opt/s3fs/bucket" ]

HEALTHCHECK \
  --interval=15s \
  --timeout=5s \
  --start-period=15s \
  --retries=2 \
  CMD [ "/usr/local/bin/healthcheck.sh" ]

# The default is to perform all system-level mounting as part of the entrypoint
# to then have a command that will keep listing the files under the main share.
# Listing the files will keep the share active and avoid that the remote server
# closes the connection.
ENTRYPOINT [ "tini", "-g", "--", "docker-entrypoint.sh" ]
CMD [ "empty.sh" ]
