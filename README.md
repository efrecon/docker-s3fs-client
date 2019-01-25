# Dockerised s3fs Client

This container facilitates mounting of remote S3 buckets resources into a
container. Mounting is implemented using [s3fs]. Used with the proper creation
options, you should be able to bind-mount back the remote bucket onto a host
directory in a way that makes its content available to processes (and other
containers) on the host.

  [s3fs]: https://github.com/s3fs-fuse/s3fs-fuse

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
    -v /mnt/tmp:/mnt/bucket:rshared \
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
  format specified by [s3fs]. This can be empty, in which case data will be taken from the other authorisation-related environment variables.
* `AWS_S3_ACCESS_KEY_ID` is the access key to the S3 bucket, this is only used
  whenever `AWS_S3_AUTHFILE` is empty.
* `AWS_S3_SECRET_ACCESS_KEY` is the secret access key to the S3 bucket, this is
  only used whenever `AWS_S3_AUTHFILE` is empty. Note however that the variable `AWS_S3_SECRET_ACCESS_KEY_FILE` has precedence over this one.
* `AWS_S3_SECRET_ACCESS_KEY_FILE` points instead to a file that will contain the
  secret access key to the S3 bucket. When this is present, the password will be
  taken from the file instead of from the `AWS_S3_SECRET_ACCESS_KEY` variable.
  If that variable existed, it will be disregarded. This makes it easy to pass
  passwords using Docker [secrets]. This is only ever used whenever
  `AWS_S3_AUTHFILE` is empty.
* `AWS_S3_URL` is the URL to the Amazon service. This can be used to mount
  external services that implement a compatible API.
* `AWS_S3_MOUNT` is the location within the container where to mounte the
  WebDAV resource. This defaults to `/mnt/webdrive` and is not really meant to
  be changed.
* `OWNER` is the user ID for the owner of the share inside the container.
* `S3FS_DEBUG` can be set to `1` to get some debugging information from [s3fs].
* `S3FS_ARGS` can contain some additional options to passed to [s3fs].

  [secrets]: https://docs.docker.com/engine/swarm/secrets/

## Commands

By default, this container will keep listing the content of the mounted
directory at regular intervals. This is implemented by the [command](./ls.sh)
that it is designed to execute once the remote bucket has been mounted. If you
did not wish this behaviour, pass `empty.sh` as the command instead.

Note that both of these commands ensure that the remote bucket is unmounted from
the mountpoint at termination, so you should really pick one or the other to
allow for proper operation. If the mountpoint was not unmounted, your mount
system will be unstable as it will contain an unknown entry.