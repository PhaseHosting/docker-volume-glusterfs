# Docker volume plugin for GlusterFS

This plugin uses GlusterFS as distributed data storage for containers.

[![Release](https://img.shields.io/github/release/watson81/docker-volume-glusterfs.svg)](https://github.com/watson81/docker-volume-glusterfs/releases/latest)
[![Maintenance](https://img.shields.io/maintenance/yes/2017.svg)]() 
[![TravisCI](https://travis-ci.org/watson81/docker-volume-glusterfs.svg)](https://travis-ci.org/watson81/docker-volume-glusterfs)

## Installation

You can download pre-compiled binaries for variety of operating systems and platforms on the [releases page](https://github.com/watson81/docker-volume-glusterfs/releases).

Alternatively, you can compile and run the latest version using go:

```
$ go get github.com/watson81/docker-volume-glusterfs
```

## Usage

This plugin doesn't create volumes in your GlusterFS cluster yet, so you'll have to create them yourself first.

1 - Start the plugin using this command:

```
$ sudo docker-volume-glusterfs -servers gfs-1:gfs-2:gfs-3
```

We use the flag `-servers` to specify where to find the GlusterFS servers. The server names are separated by colons.

2 - Start your docker containers with the option `--volume-driver=glusterfs` and use the first part of `--volume` to specify the remote volume that you want to connect to:

```
$ sudo docker run --volume-driver glusterfs --volume datastore:/data alpine touch /data/hello
```

See this video for a slightly longer usage explanation:

https://youtu.be/SVtsT9WVujs

### Volume creation on demand

This extension can create volumes on the remote cluster if you install https://github.com/aravindavk/glusterfs-rest in one of the nodes of the cluster.

You need to set two extra flags when you start the extension if you want to let containers create their volumes on demand:

- rest: is the URL address to the remote api.
- gfs-base: is the base path where the volumes will be created.

This is an example of the command line to start the plugin:

```
$ docker-volume-glusterfs -servers gfs-1:gfs2 \
    -rest http://gfs-1:9000 -gfs-base /var/lib/gluster/volumes
```

These volumes are replicated among all the peers in the cluster that you specify in the `-servers` flag.

## LICENSE

docker-volume-glusterfs is licensed under the [MIT](LICENSE) license.
