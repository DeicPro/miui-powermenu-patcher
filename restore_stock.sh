#!/system/bin/sh
# by xda@DarthJabba

PATCHDIR=/data/miui-powermenu-patcher

# display message and terminate script (optionally supply exit code)
Abort()
{
  echo "$1"
  exit $2
}

# allow user to supply patchdir from command line, with "-d <dir>"
[ "$1" = "-d" ] && [ -n "$2" ] && PATCHDIR=$2

# some error checking
[ ! -d $PATCHDIR ] && Abort "Invalid directory: \"$PATCHDIR\"" "1"

# get correct Android version for backed up files
ANDROID_VER=$(getprop "ro.build.version.incremental")
[ -z "$ANDROID_VER" ] && ANDROID_VER=old_android

# check for files - restore all, or nothing
[ ! -f $PATCHDIR/$ANDROID_VER/stock/system/framework/android.policy.jar ] && Abort "No android.policy.jar backup" "2"
[ ! -f $PATCHDIR/$ANDROID_VER/stock/system/media/theme/default/powermenu ] && Abort "No powermenu backup" "3"

echo "Mounting system (rw)..."
mount -w -o remount /system

echo "Restoring stock files ..."
cp -af $PATCHDIR/$ANDROID_VER/stock/system/framework/android.policy.jar /system/framework/android.policy.jar
cp -af $PATCHDIR/$ANDROID_VER/stock/system/media/theme/default/powermenu /system/media/theme/default/powermenu

echo "Mounting system (ro)..."
mount -r -o remount /system

echo "Finished restoring stock files"
