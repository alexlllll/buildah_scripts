#!/bin/bash

set -ex

newcontainer=$(buildah from centos:7)
scratchmnt=$(buildah mount ${newcontainer})

# config
buildah config --author "https://github.com/alexlllll" "$newcontainer"

buildah run "${newcontainer}" -- yum install -y epel-release sudo
#buildah run "${newcontainer}" -- curl -o /etc/yum.repos.d/scylla.repo -L http://repositories.scylladb.com/scylla/repo/bef359fd-435b-430d-bb11-e70ca1b8b390/centos/scylladb-3.1.repo
buildah run "${newcontainer}" -- curl http://downloads.scylladb.com/rpm/unstable/centos/master/latest/scylla.repo -o /etc/yum.repos.d/scylla.repo
buildah run "${newcontainer}" -- yum install -y scylla supervisor
buildah run "${newcontainer}" -- mkdir -p /var/log/scylla /etc/supervisor.conf.d
buildah run "${newcontainer}" -- scylla_dev_mode_setup --developer-mode 1

# set env
buildah config --env PATH=/opt/scylladb/python3/bin:$PATH "${newcontainer}"

# add files
buildah add "${newcontainer}" includes/scylla-service.sh /scylla-service.sh 
buildah add "${newcontainer}" includes/scylla-jmx-service.sh /scylla-jmx-service.sh
buildah add "${newcontainer}" includes/scylla-server /etc/sysconfig/scylla-server
buildah add "${newcontainer}" includes/supervisord.conf /etc/supervisord.conf
buildah add "${newcontainer}" includes/scylla-server.conf /etc/supervisord.conf.d/scylla-server.conf
buildah add "${newcontainer}" includes/scylla-jmx.conf /etc/supervisord.conf.d/scylla-jmx.conf
buildah run "${newcontainer}" -- chmod +x /scylla-service.sh /scylla-jmx-service.sh

# Clean up yum cache
if [ -d "${scratchmnt}" ]; then
  rm -rf "${scratchmnt}"/var/cache/yum
fi

# configure container label and entrypoint
buildah config --label name=el7-scylladb ${newcontainer}
buildah config --cmd "/usr/bin/supervisord -c /etc/supervisord.conf" ${newcontainer}

# configure expose ports
buildah config --port 10000 --port 9042 --port 9160 --port 9180 --port 7000 --port 7001 ${newcontainer}

# commit the image
buildah unmount ${newcontainer}
buildah commit ${newcontainer} el7-scylladb
