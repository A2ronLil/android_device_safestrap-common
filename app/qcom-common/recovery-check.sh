#!/system/bin/sh
# By Hashcode
# Last Editted: 10/29/2012
PATH=/system/bin:/system/xbin
BLOCK_DIR=/dev/block
BLOCKNAME_DIR=$BLOCK_DIR/platform/msm_sdcc.1/by-name
SYS_BLOCK=$BLOCKNAME_DIR/systemorig
SYS_BLOCK_FSTYPE=ext4

vers=0
alt_boot_mode=0

INSTALLPATH=$1
RECOVERY_DIR=/etc/safestrap

if [ -f $SYS_BLOCK ]; then
	PRIMARYSYS=`$INSTALLPATH/busybox ls -l $BLOCKNAME_DIR/ | $INSTALLPATH/busybox grep systemorig | $INSTALLPATH/busybox tail -c 22`
else
	PRIMARYSYS=`$INSTALLPATH/busybox ls -l $BLOCKNAME_DIR/ | $INSTALLPATH/busybox grep system | $INSTALLPATH/busybox tail -c 22`
fi
CURRENTSYS=`$INSTALLPATH/busybox ls -l $BLOCKNAME_DIR/system | $INSTALLPATH/busybox tail -c 22`

if [ ! "$CURRENTSYS" = "$PRIMARYSYS" ]; then
	# alt-system, needs to mount original /system
	alt_boot_mode=1
	DESTMOUNT=$INSTALLPATH/system
	if [ ! -d "$DESTMOUNT" ]; then
		$INSTALLPATH/busybox mkdir $DESTMOUNT
	fi
	$INSTALLPATH/busybox mount -t $SYS_BLOCK_FSTYPE $PRIMARYSYS $DESTMOUNT
else
	DESTMOUNT=/system
fi

if [ -f "$DESTMOUNT$RECOVERY_DIR/flags/version" ]; then
	vers=`$INSTALLPATH/busybox cat $DESTMOUNT$RECOVERY_DIR/flags/version`
fi

if [ ! "$CURRENTSYS" = "$PRIMARYSYS" ]; then
	$INSTALLPATH/busybox umount $DESTMOUNT
fi
echo "$vers:$alt_boot_mode"

