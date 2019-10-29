#!/bin/bash

set -ex

# start new container from scratch
newcontainer=$(buildah from scratch)
scratchmnt=$(buildah mount ${newcontainer})

# install the packages
dnf install --installroot ${scratchmnt} bash coreutils glibc-langpack-en microdnf centos-release tar gzip findutils \
	--disablerepo="*" \
	--enablerepo=BaseOS \
	--releasever 8 \
	--nodocs \
	--setopt=install_weak_deps=false \
	-y \
	/	

buildah run "${newcontainer}" -- microdnf install --nodocs -y go-toolset git make

# Clean up yum cache
if [ -d "${scratchmnt}" ]; then
  rm -rf "${scratchmnt}"/var/cache/dnf "${scratchmnt}"/var/log/dnf* "${scratchmnt}"/var/lib/dnf "${scratchmnt}"/var/cache/yum
fi

# configure container label and entrypoint
buildah config --label name=el8-centos8-golang ${newcontainer}
buildah config --cmd /bin/bash ${newcontainer}

# commit the image
buildah unmount ${newcontainer}
buildah commit ${newcontainer} el8-centos8-golang
