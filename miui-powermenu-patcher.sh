#!/system/bin/sh
# by xda@Deic

PATCHDIR=/data/miui-powermenu-patcher
SMALIFILE=$PATCHDIR/android.policy.jar.out/smali/com/android/internal/policy/impl/MiuiGlobalActions\$1.smali
MANIFESTFILE=$PATCHDIR/powermenu.out/manifest.xml
SMALI_N=1
MANIFEST_N=7
STRINGS_N=2
BIN_UNZIP=0
START_LINE=246

# display message and terminate script (optionally supply exit code)
Abort()
{
  echo "$1"
  exit $2
}

# return the full path of the running script
RunningProg()
{
local n=$(basename $0)
local d=$(dirname $0)
  [ "$d" = "." ] && echo $PWD/$n || echo $0
}

SCRIPT_DIR=$(RunningProg)

# allow user to supply patchdir from command line, with "-d <dir>"
[ "$1" = "-d" ] && [ -n "$2" ] && PATCHDIR=$1

patch_msg() {
    [ "$FIRST_C" ] && COUNT=$(($COUNT+1)) || { FILE_I=$1; FILE_N=$2; COUNT=0; }

    echo "Patching $FILE_I $COUNT/$FILE_N..."

    FIRST_C=1

    [ "$COUNT" == "$FILE_N" ] && unset FIRST_C
}

echo "Creating directories..."
mkdir -p $PATCHDIR

# some error checking
[ ! -d $PATCHDIR ] && Abort "Error creating \"$PATCHDIR\"" "1"

cd $PATCHDIR

echo "" > $PATCHDIR/miui-powermenu-patcher.log

## DarthJabba9 - get current Android release for backup, backup stock, and prepare for patch
ANDROID_VER=$(getprop "ro.build.version.incremental")
[ -z "$ANDROID_VER" ] && ANDROID_VER=old_android
mkdir -p $PATCHDIR/$ANDROID_VER/stock/system/framework/
mkdir -p $PATCHDIR/$ANDROID_VER/stock/system/media/theme/default/

# backup stock files
echo "Backing up files..."
[ ! -f $PATCHDIR/$ANDROID_VER/stock/system/framework/android.policy.jar ] && {
  cp -af /system/framework/android.policy.jar $PATCHDIR/$ANDROID_VER/stock/system/framework/
}

[ ! -f $PATCHDIR/$ANDROID_VER/stock/system/media/theme/default/powermenu ] && {
  cp -af /system/media/theme/default/powermenu $PATCHDIR/$ANDROID_VER/stock/system/media/theme/default/
}

# create directories for patched files
mkdir -p $PATCHDIR/$ANDROID_VER/patched/system/framework/
mkdir -p $PATCHDIR/$ANDROID_VER/patched/system/media/theme/default/
# DarthJabba9 - end() #1

[ -f $PATCHDIR/wget ] || {
    # line where embedded file code start
    echo "Extracting embedded data..."
    NEW_TAIL="-n"
    # compatibility workarround with older version of tail
    busybox tail $NEW_TAIL +1 "$SCRIPT_DIR" > /dev/null 2> /dev/null || NEW_TAIL=""
    busybox tail $NEW_TAIL +$START_LINE "$SCRIPT_DIR" | busybox base64 -d > $PATCHDIR/wget.zip
    unzip -o $PATCHDIR/wget.zip wget >> $PATCHDIR/miui-powermenu-patcher.log 2>&1
    rm -f $PATCHDIR/wget.zip
    chmod 755 $PATCHDIR/wget
}

# DarthJabba9 - check for files or separate bin.zip
[ ! -x $PATCHDIR/openjdk/bin/java ] || [ ! -d $PATCHDIR/openjdk/lib/arm ] && {
    BIN_ZIP=/storage/sdcard1/bin.zip
    [ -f $BIN_ZIP ] && {
        echo "Extracting environment..."
        unzip -o $BIN_ZIP "*" >> $PATCHDIR/miui-powermenu-patcher.log 2>&1
        chmod -R 755 $PATCHDIR
    }
}

[ -x $PATCHDIR/openjdk/bin/java ] && [ -d $PATCHDIR/openjdk/lib/arm ] && {
    BIN_UNZIP=1
}
# DarthJabba9 - end() #2

[ "$BIN_UNZIP" == 0 ] && {
    echo "Downloading environment..."
    $PATCHDIR/wget -nv --no-check-certificate -O $PATCHDIR/bin.zip https://raw.githubusercontent.com/DeicPro/miui-powermenu-patcher/bin/bin.zip >> $PATCHDIR/miui-powermenu-patcher.log 2>&1
    echo "Extracting environment..."
    unzip -o $PATCHDIR/bin.zip "*" >> $PATCHDIR/miui-powermenu-patcher.log 2>&1
    rm -f $PATCHDIR/bin.zip
    chmod -R 755 $PATCHDIR
}

echo "Checking for patch updates..."
$PATCHDIR/wget -nv --no-check-certificate -O $PATCHDIR/update.sh https://raw.githubusercontent.com/DeicPro/miui-powermenu-patcher/master/update.sh >> $PATCHDIR/miui-powermenu-patcher.log 2>&1

[ -f $PATCHDIR/patch.sh ] && source $PATCHDIR/patch.sh
[ -f $PATCHDIR/update.sh ] && source $PATCHDIR/update.sh

[ "$version" ] && [ "$lastest_version" ] && [ "$lastest_version" != "$version" ] || [ ! -f $PATCHDIR/patch.sh ] && {
    echo "Downloading patches..."
    $PATCHDIR/wget -nv --no-check-certificate -O $PATCHDIR/patch.sh https://raw.githubusercontent.com/DeicPro/miui-powermenu-patcher/master/patch.sh >> $PATCHDIR/miui-powermenu-patcher.log 2>&1
    source patch.sh
}

## decompile
echo "Preparing environment..."
if [ ! -f /data/app/per.pqy.apktool*/*.apk ]; then
    mkdir -p /data/data/per.pqy.apktool/apktool/openjdk/lib
    cp -f openjdk/lib/ld.so /data/data/per.pqy.apktool/apktool/openjdk/lib/ld.so
    chmod -R 755 /data/data/per.pqy.apktool
fi

cp -f /system/framework/android.policy.jar android.policy.jar

export LD_PRELOAD=
export LD_LIBRARY_PATH=$PATCHDIR/openjdk/lib/arm:$LD_LIBRARY_PATH

umask 000

run_apktool() {
    (exec $PATCHDIR/openjdk/bin/java -Xmx1024m -Djava.io.tmpdir=$PATCHDIR -jar $PATCHDIR/apktool-2.2.2.jar -p $PATCHDIR "$@" >> $PATCHDIR/miui-powermenu-patcher.log 2>&1)
}

echo "Decompiling android.policy.jar..."
run_apktool -f d android.policy.jar

patch_msg smali $SMALI_N

patch_smali

patch_msg

rm -f ${SMALIFILE}.bak

## recompile
echo "Recompiling android.policy.jar..."
run_apktool b -a $PATCHDIR/aapt6.0 android.policy.jar.out

[ -f /data/app/per.pqy.apktool*/*.apk ] || rm -rf /data/data/per.pqy.apktool

cp -f /system/media/theme/default/powermenu powermenu

mkdir -p $PATCHDIR/powermenu.out

echo "Decompressing powermenu..."
unzip -o $PATCHDIR/powermenu "*" -d $PATCHDIR/powermenu.out >> $PATCHDIR/miui-powermenu-patcher.log 2>&1

patch_msg manifest $MANIFEST_N

patch_manifest_1

patch_msg

patch_manifest_2

patch_msg

patch_manifest_3

patch_msg

patch_manifest_4

patch_msg

patch_manifest_5

patch_msg

patch_manifest_6

patch_msg

patch_manifest_7

patch_msg

rm -f ${MANIFESTFILE}.bak

patch_msg strings $STRINGS_N
# patching english strings
patch_strings "" "Power off" "Tap to power off" "Tap to reboot to recovery" "Tap to reboot to fastboot"

patch_msg
# patching spanish strings
patch_strings "_es_ES" "Apagar" "Toque para apagar" "Toque para reiniciar al recovery" "Toque para reiniciar al fastboot"

patch_msg

echo "Adding new images to powermenu..."
cp -f recovery.png powermenu.out/
cp -f recovery_big.png powermenu.out/
cp -f fastboot.png powermenu.out/
cp -f fastboot_big.png powermenu.out/

cd $PATCHDIR/powermenu.out

echo "Recompressing powermenu..."
$PATCHDIR/7za a -mx9 -tzip powermenu.zip * >> $PATCHDIR/miui-powermenu-patcher.log 2>&1

echo "Mounting system (rw)..."

mount -w -o remount /system

echo "Copying patched files to system..."
cp -f $PATCHDIR/android.policy.jar.out/dist/android.policy.jar /system/framework/android.policy.jar

cp -f powermenu.zip /system/media/theme/default/powermenu

echo "Mounting system (ro)..."

mount -r -o remount /system

# DarthJabba9 - copy patched files to another place
echo "Backing up patched files..."
cp -f $PATCHDIR/android.policy.jar.out/dist/android.policy.jar $PATCHDIR/$ANDROID_VER/patched/system/framework/android.policy.jar
cp -f powermenu.zip $PATCHDIR/$ANDROID_VER/patched/system/media/theme/default/powermenu
# DarthJabba9 - end() #3

cd $PATCHDIR

rm -rf android.policy.jar.out powermenu.out
rm -f android.policy.jar powermenu

echo "Done"

exit
