#!/bin/bash

set -ex

# start new container from scratch
newcontainer=$(buildah from centos:7)
scratchmnt=$(buildah mount ${newcontainer})

# config
buildah config --author "https://github.com/alexlllll" "$newcontainer"

buildah run "${newcontainer}" -- yum install -y epel-release sudo
buildah run "${newcontainer}" -- curl -o /etc/yum.repos.d/scylla.repo -L http://repositories.scylladb.com/scylla/repo/bef359fd-435b-430d-bb11-e70ca1b8b390/centos/scylladb-3.1.repo
buildah run "${newcontainer}" -- yum install -y scylla
buildah run "${newcontainer}" -- scylla_dev_mode_setup --developer-mode 1

# set env
buildah config --env PATH=/opt/scylladb/python3/bin:$PATH "${newcontainer}"

# add files
buildah add "${newcontainer}" includes/scylla-service.sh /scylla-service.sh 
buildah add "${newcontainer}" includes/scylla-jmx-service.sh /scylla-jmx-service.sh

# Clean up yum cache
if [ -d "${scratchmnt}" ]; then
  rm -rf "${scratchmnt}"/var/cache/yum
fi

# configure container label and entrypoint
buildah config --label name=el7-scylladb ${newcontainer}
buildah config --cmd /bin/bash ${newcontainer}

# configure expose ports
buildah config --port 10000 --port 9042 --port 9160 --port 9180 --port 7000 --port 7001 ${newcontainer}

# commit the image
buildah unmount ${newcontainer}
buildah commit ${newcontainer} el7-scylladb
