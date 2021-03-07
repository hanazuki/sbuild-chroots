#!/bin/bash
set -eux

BUILD_DIST=${BUILD_OS#*-}

DEBIAN_MIRROR=http://deb.debian.org/debian
SECDEB_MIRROR=http://deb.debian.org/debian-security
UBUNTU_MIRROR=http://azure.archive.ubuntu.com/ubuntu
UBUNTU_PORTS_MIRROR=http://ports.ubuntu.com/ubuntu-ports

EXTRA_PACKAGES=eatmydata,ccache,gnupg

chroot_name=${BUILD_OS}-${BUILD_ARCH}
chroot_path=/srv/chroot/${chroot_name}
tarball=$PWD/${BUILD_OS}-${BUILD_ARCH}-sbuild.tar.gz

args=(--verbose --arch="${BUILD_ARCH}" --debootstrap=qemu-debootstrap --include="$EXTRA_PACKAGES" --make-sbuild-tarball "$tarball")

case "$BUILD_OS" in
  debian-*)
    mirror=$DEBIAN_MIRROR
    if [[ $BUILD_DIST == unstable ]]; then
      args+=(--alias="UNRELEASED-${BUILD_ARCH}-sbuild")
    else
      args+=(--extra-repository="deb $DEBIAN_MIRROR ${BUILD_DIST}-updates main" --extra-repository="deb $SECDEB_MIRROR ${BUILD_DIST}/updates main")
    fi
    ;;

  ubuntu-*)
    case "${BUILD_ARCH}" in
      i386|amd64)
        mirror=$UBUNTU_MIRROR;;
      *)
        mirror=$UBUNTU_PORTS_MIRROR;;
    esac

    sudo ln -s gutsy "/usr/share/debootstrap/scripts/${BUILD_DIST}" || :
    args+=(--components=main,universe --extra-repository="deb $mirror ${BUILD_DIST}-updates main universe" --extra-repository="deb $mirror ${BUILD_DIST}-security main universe")
    ;;

  *)
    echo >&2 "Unknown BUILD_OS: $BUILD_OS"
    exit 1
    ;;
esac

sudo sbuild-createchroot "${args[@]}"  "${BUILD_DIST}" "${chroot_path}" "$mirror"
stat "$tarball"

echo "::set-output name=artifact_path::${tarball}"
