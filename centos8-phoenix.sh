#!/bin/bash

set -ex

# start new container from scratch
newcontainer=$(buildah from scratch)
scratchmnt=$(buildah mount ${newcontainer})

# install the packages
dnf install --installroot ${scratchmnt} bash coreutils glibc-minimal-langpack microdnf centos-release unzip \
	--disablerepo="*" \
	--enablerepo=BaseOS \
	--releasever 8 \
	--nodocs \
	--setopt=install_weak_deps=false \
	-y \
	/	

buildah run "${newcontainer}" -- microdnf install -y epel-release
buildah run "${newcontainer}" -- microdnf install -y --enablerepo PowerTools erlang
buildah run "${newcontainer}" -- mkdir /opt/elixir 
buildah run "${newcontainer}" -- curl -L https://github.com/elixir-lang/elixir/releases/download/v1.9.1/Precompiled.zip -o /tmp/Precompiled.zip
buildah run "${newcontainer}" -- unzip /tmp/Precompiled.zip -d /opt/elixir

# set env
buildah config --env PATH=$PATH:/opt/bin/elixir "${newcontainer}"
buildah config --env LANG="en_US.UTF-8" "${newcontainer}"
buildah config --env LC_CTYPE="en_US.UTF-8" "${newcontainer}"

# install phoenix
buildah run "${newcontainer}" -- mix local.hex --force

# Clean up yum cache
if [ -d "${scratchmnt}" ]; then
  rm -rf "${scratchmnt}"/var/cache/dnf "${scratchmnt}"/var/log/dnf* "${scratchmnt}"/var/lib/dnf "${scratchmnt}"/tmp/Precompiled.zip
fi

# configure container label and entrypoint
buildah config --label name=el8-phoenix ${newcontainer}
buildah config --cmd /bin/bash ${newcontainer}

# commit the image
buildah unmount ${newcontainer}
buildah commit ${newcontainer} el8-phoenix
