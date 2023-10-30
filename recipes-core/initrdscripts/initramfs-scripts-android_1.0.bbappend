FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
S = "${WORKDIR}"
RDEPENDS:${PN} += "e2fsprogs-e2fsck e2fsprogs-mke2fs psplash android-tools-adbd gptfdisk"
