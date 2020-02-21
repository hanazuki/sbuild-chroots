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
common_args=(--verbose --arch="${BUILD_ARCH}" --debootstrap=qemu-debootstrap --include="$EXTRA_PACKAGES" --make-sbuild-tarball "$tarball")

case "$BUILD_OS" in
    debian-*)
        if [[ $BUILD_DIST == unstable ]]; then
            sudo sbuild-createchroot "${common_args[@]}" --alias="UNRELEASED-${BUILD_ARCH}-sbuild" "${BUILD_DIST}" "${chroot_path}" "$DEBIAN_MIRROR"
        else
            sudo sbuild-createchroot "${common_args[@]}" --extra-repository="deb $DEBIAN_MIRROR ${BUILD_DIST}-updates main" --extra-repository="deb $SECDEB_MIRROR ${BUILD_DIST}/updates main" "${BUILD_DIST}" "${chroot_path}" "$DEBIAN_MIRROR"
        fi
        ;;

    ubuntu-*)
        sudo ln -s gutsy "/usr/share/debootstrap/scripts/${BUILD_DIST}" || :
        sudo sbuild-createchroot "${common_args[@]}" --components=main,universe --extra-repository="deb $UBUNTU_MIRROR ${BUILD_DIST}-updates main universe" --extra-repository="deb $UBUNTU_MIRROR ${BUILD_DIST}-security main universe" "${BUILD_DIST}" "${chroot_path}" "$UBUNTU_MIRROR"
        ;;

    *)
        echo >&2 "Unknown BUILD_OS: $BUILD_OS"
        exit 1
        ;;
esac

stat "$tarball"
