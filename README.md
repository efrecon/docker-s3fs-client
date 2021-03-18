# Dockerised s3fs Client

This Docker image facilitates mounting of remote S3 buckets resources into
containers. Mounting is performed through the fuse [s3fs] implementation. The
image basically implements a docker [volume] on the cheap: Used with the proper
creation options (see below) , you should be able to bind-mount back the remote
bucket onto a host directory. This directory will make the content of the bucket
available to processes, but also all other containers on the host. The image
automatically unmount the remote bucket on container termination.

  [s3fs]: https://github.com/s3fs-fuse/s3fs-fuse
  [volume]: https://docs.docker.com/storage/

The image [tags] follow the versions from the [s3fs] implementation. New
versions of [s3fs] will automatically be picked up when [rebuilding]. [s3fs] is
compiled from the tagged git versions from the main repository.

  [tags]: https://cloud.docker.com/repository/docker/efrecon/s3fs/tags
  [rebuilding]: ./hooks/build

## Example

Provided the existence of a directory called `/mnt/tmp` on the host, the
following command would mount a remote S3 bucket and bind-mount the remote
resource onto the host's `/mnt/tmp` in a way that makes the remote files
accessible to processes and/or other containers running on the same host.

```Shell
docker run -it --rm \
    --device /dev/fuse \
    --cap-add SYS_ADMIN \
    --security-opt "apparmor=unconfined" \
    --env "AWS_S3_BUCKET=<bucketName>" \
    --env "AWS_S3_ACCESS_KEY_ID=<accessKey>" \
    --env "AWS_S3_SECRET_ACCESS_KEY=<secretKey>" \
    --env UID=$(id -u) \
    --env GID=$(id -g) \
    -v /mnt/tmp:/opt/s3fs/bucket:rshared \
    efrecon/s3fs
```

The `--device`, `--cap-add` and `--security-opt` options and their values are to
make sure that the container will be able to make available the S3 bucket
using FUSE. `rshared` is what ensures that bind mounting makes the files and
directories available back to the host and recursively to other containers.

## Container Options

A series of environment variables, most led by `AWS_S3_` can be used to
parametrise the container:

* `AWS_S3_BUCKET` should be the name of the bucket, this is mandatory.
* `AWS_S3_AUTHFILE` is the path to an authorisation file compatible with the
  format specified by [s3fs]. This can be empty, in which case data will be
  taken from the other authorisation-related environment variables.
* `AWS_S3_ACCESS_KEY_ID` is the access key to the S3 bucket, this is only used
  whenever `AWS_S3_AUTHFILE` is empty.
* `AWS_S3_SECRET_ACCESS_KEY` is the secret access key to the S3 bucket, this is
  only used whenever `AWS_S3_AUTHFILE` is empty. Note however that the variable
  `AWS_S3_SECRET_ACCESS_KEY_FILE` has precedence over this one.
* `AWS_S3_SECRET_ACCESS_KEY_FILE` points instead to a file that will contain the
  secret access key to the S3 bucket. When this is present, the password will be
  taken from the file instead of from the `AWS_S3_SECRET_ACCESS_KEY` variable.
  If that variable existed, it will be disregarded. This makes it easy to pass
  passwords using Docker [secrets]. This is only ever used whenever
  `AWS_S3_AUTHFILE` is empty.
* `AWS_S3_URL` is the URL to the Amazon service. This can be used to mount
  external services that implement a compatible API.
* `AWS_S3_MOUNT` is the location within the container where to mounte the
  WebDAV resource. This defaults to `/opt/s3fs/bucket` and is not really meant to
  be changed.
* `UID` is the user ID for the owner of the share inside the container.
* `GID` is the group ID for the owner of the share inside the container.
* `S3FS_DEBUG` can be set to `1` to get some debugging information from [s3fs].
* `S3FS_ARGS` can contain some additional options to be blindly passed to
  [s3fs].
  * options are supposed to be given comma-separated, e.g. "use_path_request_style,allow_other,default_acl=public-read"

  [secrets]: https://docs.docker.com/engine/swarm/secrets/

## Commands

By default, this container will be silent and running `empty.sh` as its command.
If you wanted to check for liveness, you can pass the command `ls.sh` instead,
which will keep listing the content of the mounted directory at regular
intervals. Both these commands ensure that the remote bucket is unmounted from
the mountpoint at termination, so you should really pick one or the other to
allow for proper operation. If the mountpoint was not unmounted, your mount
system will be unstable as it will contain an unknown entry.

Automatic unmounting is achieved through a combination of a `trap` in the
command being executed and [tini]. [tini] is made available directly in this
image to make it possible to run in [Swarm] environments.

  [tini]: https://github.com/krallin/tini
  [Swarm]: https://docs.docker.com/engine/swarm/

## Versions and Tags

The docker [image] has [tags] that automatically match the list of official
[versions] of [s3fs]. This is achieved through using the github API to discover
the list of tags starting with `v` and building a separate image for each of
them. The image itself builds upon [alpine]. There is no release for version
1.87 as it contains a regression that was [fixed] after the release.

  [image]: https://cloud.docker.com/repository/docker/efrecon/s3fs
  [tags]: https://cloud.docker.com/repository/docker/efrecon/s3fs/tags
  [versions]: https://github.com/s3fs-fuse/s3fs-fuse/tags
  [alpine]: https://hub.docker.com/_/alpine
  [fixed]: https://github.com/s3fs-fuse/s3fs-fuse/pull/1365