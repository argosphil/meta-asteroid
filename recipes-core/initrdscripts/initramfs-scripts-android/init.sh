#! /bin/sh

# machine.conf should provide $sdcard_partition
. /machine.conf

# Logging functions
info() {
    echo "$1" > /dev/ttyprintk
}

fail() {
    echo "Failed" > /dev/ttyprintk
    echo "$1" > /dev/ttyprintk
    echo "Waiting for 15 seconds before rebooting ..." > /dev/ttyprintk
    sleep 15s
    reboot
}

# Populates /dev (called for /dev and /rfs/dev)
setup_devtmpfs() {
    mount -t devtmpfs -o mode=0755,nr_inodes=0 devtmpfs $1/dev

    mkdir $1/dev/pts
    mount -t devpts none $1/dev/pts/

    test -c $1/dev/fd     || ln -sf /proc/self/fd $1/dev/fd
    test -c $1/dev/stdin  || ln -sf fd/0 $1/dev/stdin
    test -c $1/dev/stdout || ln -sf fd/1 $1/dev/stdout
    test -c $1/dev/stderr || ln -sf fd/2 $1/dev/stderr
    test -c $1/dev/socket || mkdir -m 0755 $1/dev/socket
}

info "Mounting relevant filesystems ..."
mkdir -m 0755 /proc
mount -t proc proc /proc
mkdir -m 0755 /sys
mount -t sysfs sys /sys
mkdir -p /dev
setup_devtmpfs ""

# Checks wether we need to start adbd for interactive debugging
cat /proc/cmdline | grep debug-ramdisk
    mkdir -p /dev/usb-ffs/adb
    mount -t functionfs adb /dev/usb-ffs/adb

    echo 0 > /sys/class/android_usb/android0/enable
    echo 18d1 > /sys/class/android_usb/android0/idVendor
    echo d002 > /sys/class/android_usb/android0/idProduct
    echo adb > /sys/class/android_usb/android0/f_ffs/aliases
    echo ffs > /sys/class/android_usb/android0/functions
    echo AsteroidOS > /sys/class/android_usb/android0/iManufacturer
    echo InitRamDisk > /sys/class/android_usb/android0/iProduct
    serial="$(cat /proc/cmdline | sed 's/.*androidboot.serialno=//' | sed 's/ .*//')"
    echo $serial > /sys/class/android_usb/android0/iSerial
    echo 1 > /sys/class/android_usb/android0/enable

    /usr/bin/android-gadget-setup adb
    /usr/bin/adbd &
    while true; do
	echo 0 > /sys/class/backlight/panel_0/brightness;
	sleep 1;
	cat /sys/class/backlight/panel_0/max_brightness > /sys/class/backlight/panel_0/brightness;
	sleep 1;
    done &
    while sleep 1; do : ; done

rotation=0
if [ -e /etc/rotation ]; then
    read rotation < /etc/rotation
fi

if [ -x /usr/bin/msm-fb-refresher ] ; then
    /usr/bin/msm-fb-refresher
fi

/usr/bin/psplash --angle $rotation --no-console-switch &

# The sdcard partition may be the rootfs itself or contain a loop file
info "Mounting sdcard..."
mkdir -m 0777 /sdcard /loop

BOOT_DIR=/sdcard
mount -t auto -o rw,noatime,nodiratime /dev/mmcblk0p28 /sdcard

setup_devtmpfs $BOOT_DIR

info "Move the /proc and /sys filesystems..."
umount -l /proc
umount -l /sys
mount -t proc proc $BOOT_DIR/proc
mount -t sysfs sys $BOOT_DIR/sys
mount -t tmpfs run $BOOT_DIR/run

echo FIFO $BOOT_DIR/run > /run/psplash_fifo
# We need to give psplash time to create the new named pipe.
sleep 1

info "Switching to rootfs..."
mkdir $BOOT_DIR/initrd
pivot_root $BOOT_DIR /initrd
exec /lib/systemd/systemd
