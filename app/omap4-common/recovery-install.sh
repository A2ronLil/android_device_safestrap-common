#!/system/bin/sh
# By Hashcode
# Last Editted: 11/07/2012
PATH=/system/bin:/system/xbin
BLOCK_DIR=/dev/block
BLOCKNAME_DIR=$BLOCK_DIR/platform/omap/omap_hsmmc.1/by-name
SYS_BLOCK=$BLOCKNAME_DIR/systemorig
SYS_BLOCK_FSTYPE=ext4
HIJACK_BIN=logwrapper

INSTALLPATH=$1
RECOVERY_DIR=/etc/safestrap
LOGFILE=$INSTALLPATH/action-install.log

chmod 755 $INSTALLPATH/busybox

echo "install path=$INSTALLPATH/install-files" > $LOGFILE
if [ -d $INSTALLPATH/install-files ]; then
	rm -r $INSTALLPATH/install-files >> $LOGFILE
fi

$INSTALLPATH/busybox unzip $INSTALLPATH/install-files.zip  -d $INSTALLPATH >> $LOGFILE
if [ ! -d $INSTALLPATH/install-files ]; then
	echo 'ERR: Zip file didnt extract correctly.  Installation aborted.' >> $LOGFILE
	exit 1
fi

if [ -f $SYS_BLOCK ]; then
	PRIMARYSYS=`$INSTALLPATH/busybox ls -l $BLOCKNAME_DIR/ | $INSTALLPATH/busybox grep systemorig | $INSTALLPATH/busybox tail -c 22`
else
	PRIMARYSYS=`$INSTALLPATH/busybox ls -l $BLOCKNAME_DIR/ | $INSTALLPATH/busybox grep system | $INSTALLPATH/busybox tail -c 22`
fi
CURRENTSYS=`$INSTALLPATH/busybox ls -l $BLOCKNAME_DIR/system | $INSTALLPATH/busybox tail -c 22`
# determine our active system, and mount/remount accordingly
if [ ! "$CURRENTSYS" = "$PRIMARYSYS" ]; then
	# alt-system, needs to mount original /system
	DESTMOUNT=$INSTALLPATH/system
	if [ ! -d "$DESTMOUNT" ]; then
		$INSTALLPATH/busybox mkdir $DESTMOUNT
		$INSTALLPATH/busybox chmod 755 $DESTMOUNT
	fi
	$INSTALLPATH/busybox mount -t $SYS_BLOCK_FSTYPE $PRIMARYSYS $DESTMOUNT >> $LOGFILE
else
	DESTMOUNT=/system
	sync
	$INSTALLPATH/busybox mount -o remount,rw $DESTMOUNT >> $LOGFILE
fi

# check for a $HIJACK_BIN.bin file and its not there, make a copy
if [ ! -f "$DESTMOUNT/bin/$HIJACK_BIN.bin" ]; then
	$INSTALLPATH/busybox cp $DESTMOUNT/bin/$HIJACK_BIN $DESTMOUNT/bin/$HIJACK_BIN.bin >> $LOGFILE
	$INSTALLPATH/busybox chown 0.2000 $DESTMOUNT/bin/$HIJACK_BIN.bin >> $LOGFILE
	$INSTALLPATH/busybox chmod 755 $DESTMOUNT/bin/$HIJACK_BIN.bin >> $LOGFILE
fi
$INSTALLPATH/busybox rm $DESTMOUNT/bin/$HIJACK_BIN >> $LOGFILE
$INSTALLPATH/busybox cp -f $INSTALLPATH/install-files/bin/$HIJACK_BIN $DESTMOUNT/bin >> $LOGFILE
$INSTALLPATH/busybox chown 0.2000 $DESTMOUNT/bin/$HIJACK_BIN >> $LOGFILE
$INSTALLPATH/busybox chmod 755 $DESTMOUNT/bin/$HIJACK_BIN >> $LOGFILE

# delete any existing /system/etc/safestrap dir
if [ -d "$DESTMOUNT$RECOVERY_DIR" ]; then
	$INSTALLPATH/busybox rm -rf $DESTMOUNT$RECOVERY_DIR >> $LOGFILE
fi
# extract the new dirs to /system
$INSTALLPATH/busybox cp -R $INSTALLPATH/install-files$RECOVERY_DIR $DESTMOUNT/etc >> $LOGFILE
$INSTALLPATH/busybox chown 0.2000 $DESTMOUNT$RECOVERY_DIR/* >> $LOGFILE
$INSTALLPATH/busybox chmod 755 $DESTMOUNT$RECOVERY_DIR/* >> $LOGFILE

# determine our active system, and umount/remount accordingly
if [ ! "$CURRENTSYS" = "$PRIMARYSYS" ]; then
	# if we're in 2nd-system then re-enable safe boot
	$INSTALLPATH/busybox touch $DESTMOUNT$RECOVERY_DIR/flags/alt_system_mode >> $LOGFILE

	$INSTALLPATH/busybox umount $DESTMOUNT >> $LOGFILE
	$INSTALLPATH/busybox rmdir $DESTMOUNT >> $LOGFILE
else
	$INSTALLPATH/busybox mount -o ro,remount $DESTMOUNT >> $LOGFILE
fi

