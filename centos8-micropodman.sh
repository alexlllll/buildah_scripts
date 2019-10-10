#!/bin/bash

set -ex

# start new container from scratch
newcontainer=$(buildah from scratch)
scratchmnt=$(buildah mount ${newcontainer})

# install the packages
dnf install --installroot ${scratchmnt} bash coreutils glibc-minimal-langpack centos-release \
	--disablerepo="*" \
	--enablerepo=BaseOS \
	--releasever 8 \
	--nodocs \
	--setopt=install_weak_deps=false \
	-y \
	/	

dnf install --installroot ${scratchmnt} podman \
        --disablerepo="*" \
        --enablerepo=BaseOS \
        --enablerepo=AppStream \
        --releasever 8 \
        --nodocs \
        --setopt=install_weak_deps=false \
        -y \
        /

# Clean up yum cache
if [ -d "${scratchmnt}" ]; then
  rm -rf "${scratchmnt}"/var/cache/dnf "${scratchmnt}"/var/log/dnf* "${scratchmnt}"/var/lib/dnf
fi

# configure container label and entrypoint
buildah config --label name=el8-micropodman ${newcontainer}
buildah config --cmd /bin/bash ${newcontainer}

# commit the image
buildah unmount ${newcontainer}
buildah commit ${newcontainer} el8-micropodman
