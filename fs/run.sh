#!/usr/bin/env bash

# DinD: a wrapper script which allows docker to be run inside a docker container.
# Original version by Jerome Petazzoni <jerome@docker.com>
# See the blog post: https://blog.docker.com/2013/09/docker-can-now-run-within-docker/
#
# This script should be executed inside a docker container in privileged mode
# ('docker run --privileged', introduced in docker 0.6).

# Usage: dind CMD [ARG...]

# apparmor sucks and Docker needs to know that it's in a container (c) @tianon
#export container=docker

if [ -d /sys/kernel/security ] && ! mountpoint -q /sys/kernel/security; then
	mount -t securityfs none /sys/kernel/security || {
		echo >&2 'Could not mount /sys/kernel/security.'
		echo >&2 'AppArmor detection and --privileged mode might break.'
	}
fi

# this breaks concourse because it stores data in /tmp
# Mount /tmp (conditionally)
#if ! mountpoint -q /tmp; then
#	mount -t tmpfs none /tmp
#fi

#cgroup fix
cgroupfs_mount() {
        # see also https://github.com/tianon/cgroupfs-mount/blob/master/cgroupfs-mount
        if grep -v '^#' /etc/fstab | grep -q cgroup \
                || [ ! -e /proc/cgroups ] \
                || [ ! -d /sys/fs/cgroup ]; then
                return
        fi
        if ! mountpoint -q /sys/fs/cgroup; then
                mount -t tmpfs -o uid=0,gid=0,mode=0755 cgroup /sys/fs/cgroup
        fi
        (
                cd /sys/fs/cgroup
                for sys in $(awk '!/^#/ { if ($4 == 1) print $1 }' /proc/cgroups); do
                        mkdir -p $sys
                        if ! mountpoint -q $sys; then
                                if ! mount -n -t cgroup -o $sys cgroup $sys; then
                                        rmdir $sys || true
                                fi
                        fi
                done
        )
}
cgroupfs_mount

# fail on any failed command
set -e -x

# mount /var/lib/mysql as tmpfs
mv /var/lib/mysql /var/lib/mysql-cp
mkdir /var/lib/mysql
mount -t tmpfs -o size=512m tmpfs /var/lib/mysql
mv /var/lib/mysql-cp/* /var/lib/mysql
chown mysql:mysql /var/lib/mysql

# mount /var/lib/mongodb/ as tmpfs
mv /var/lib/mongodb /var/lib/mongodb-cp
mkdir /var/lib/mongodb
mount -t tmpfs -o size=512m tmpfs /var/lib/mongodb
mv /var/lib/mongodb-cp/* /var/lib/mongodb
chown mongodb:mongodb /var/lib/mongodb

# Start supervisord and services
/usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf