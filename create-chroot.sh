#!/bin/bash
set -eux

BUILD_DIST=${BUILD_OS#*-}

DEBIAN_MIRROR=http://deb.debian.org/debian
SECDEB_MIRROR=http://deb.debian.org/debian-security
UBUNTU_MIRROR=http://azure.archive.ubuntu.com/ubuntu

EXTRA_PACKAGES=eatmydata,ccache,gnupg

chroot_name=${BUILD_OS}-${BUILD_ARCH}
chroot_path=/srv/chroot/${chroot_name}
tarball=$PWD/${BUILD_OS}-${BUILD_ARCH}-sbuild.tar.gz

args=(--verbose --arch="${BUILD_ARCH}" --debootstrap=qemu-debootstrap --include="$EXTRA_PACKAGES" --make-sbuild-tarball "$tarball")

case "$BUILD_OS" in
  debian-*)
    if [[ $BUILD_DIST == unstable ]]; then
      args+=(--alias="UNRELEASED-${BUILD_ARCH}-sbuild")
    else
      args+=(--extra-repository="deb $DEBIAN_MIRROR ${BUILD_DIST}-updates main" --extra-repository="deb $SECDEB_MIRROR ${BUILD_DIST}/updates main")
    fi
    mirror=$DEBIAN_MIRROR
    ;;

  ubuntu-*)
    sudo ln -s gutsy "/usr/share/debootstrap/scripts/${BUILD_DIST}" || :
    args+=(--components=main,universe --extra-repository="deb $UBUNTU_MIRROR ${BUILD_DIST}-updates main universe" --extra-repository="deb $UBUNTU_MIRROR ${BUILD_DIST}-security main universe")
    mirror=$UBUNTU_MIRROR
    ;;

  *)
    echo >&2 "Unknown BUILD_OS: $BUILD_OS"
    exit 1
    ;;
esac

sudo sbuild-createchroot "${args[@]}"  "${BUILD_DIST}" "${chroot_path}" "$mirror"
stat "$tarball"
