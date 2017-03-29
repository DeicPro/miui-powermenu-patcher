#!/system/bin/sh
# by xda@Deic

PATCHDIR=/data/miui-powermenu-patcher
SMALIFILE=$PATCHDIR/android.policy.jar.out/smali/com/android/internal/policy/impl/MiuiGlobalActions\$1.smali
MANIFESTFILE=$PATCHDIR/powermenu.out/manifest.xml
SMALI_N=1
MANIFEST_N=7
STRINGS_N=2
BIN_UNZIP=0

patch_msg() {
    [ "$FIRST_C" ] && COUNT=$(($COUNT+1)) || { FILE_I=$1; FILE_N=$2; COUNT=0; }

    echo "Patching $FILE_I $COUNT/$FILE_N..."

    FIRST_C=1

    [ "$COUNT" == "$FILE_N" ] && unset FIRST_C
}

mkdir -p $PATCHDIR

cd $PATCHDIR

## DarthJabba9 - get current Android release for backup, backup stock, and prepare for patch
ANDROID_VER=$(getprop "ro.build.user")
[ -z "$ANDROID_VER" ] && ANDROID_VER=old_android
mkdir -p $PATCHDIR/$ANDROID_VER/stock/system/framework/
mkdir -p $PATCHDIR/$ANDROID_VER/stock/system/media/theme/default/

# backup stock files
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
    echo "Extracting wget..."
    START_LINE=200
    NEW_TAIL="-n"
    # compatibility workarround with older version of tail
    busybox tail $NEW_TAIL +1 "$0" > /dev/null 2> /dev/null || NEW_TAIL=""
    busybox tail $NEW_TAIL +$START_LINE "$0" | busybox base64 -d > $PATCHDIR/wget.zip
    unzip -o $PATCHDIR/wget.zip wget
    rm -f $PATCHDIR/wget.zip
    chmod 755 $PATCHDIR/wget
}

# DarthJabba9 - check for files or separate bin.zip
[ ! -x $PATCHDIR/openjdk/bin/java ] || [ ! -d $PATCHDIR/openjdk/lib/arm ] && {
    BIN_ZIP=/storage/sdcard1/bin.zip
    [ -f $BIN_ZIP ] && {
        echo "Extracting environment..."
        unzip -o $BIN_ZIP "*"
        chmod -R 755 $PATCHDIR
    }
}

[ -x $PATCHDIR/openjdk/bin/java ] && [ -d $PATCHDIR/openjdk/lib/arm ] && {
    BIN_UNZIP=1
}
# DarthJabba9 - end() #2

[ "$BIN_UNZIP" == 0 ] && {
    echo "Downloading environment..."
    $PATCHDIR/wget --no-check-certificate https://raw.githubusercontent.com/DeicPro/miui-powermenu-patcher/bin/bin.zip
    echo "Extracting environment..."
    unzip -o $PATCHDIR/bin.zip "*"
    rm -f $PATCHDIR/bin.zip
    chmod -R 755 $PATCHDIR
}

echo "Checking for patch updates..."
$PATCHDIR/wget --no-check-certificate https://raw.githubusercontent.com/DeicPro/miui-powermenu-patcher/master/update.sh

[ -f $PATCHDIR/patch.sh ] && source $PATCHDIR/patch.sh
[ -f $PATCHDIR/update.sh ] && source $PATCHDIR/update.sh

[ "$version" ] && [ "$lastest_version" ] && [ "$lastest_version" != "$version" ] || [ ! -f $PATCHDIR/patch.sh ] && {
    echo "Downloading patches..."
    $PATCHDIR/wget --no-check-certificate https://raw.githubusercontent.com/DeicPro/miui-powermenu-patcher/master/patch.sh
    source patch.sh
}

## decompile
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
    (exec $PATCHDIR/openjdk/bin/java -Xmx1024m -Djava.io.tmpdir=$PATCHDIR -jar $PATCHDIR/apktool-2.2.2.jar -p $PATCHDIR "$@")
}

run_apktool -f d android.policy.jar

patch_msg smali $SMALI_N

patch_smali

patch_msg

rm -f ${SMALIFILE}.bak

## recompile
run_apktool b -a $PATCHDIR/aapt6.0 android.policy.jar.out

[ -f /data/app/per.pqy.apktool*/*.apk ] || rm -rf /data/data/per.pqy.apktool

cp -f /system/media/theme/default/powermenu powermenu

mkdir -p $PATCHDIR/powermenu.out

unzip -o $PATCHDIR/powermenu "*" -d $PATCHDIR/powermenu.out

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

cp -f recovery.png powermenu.out/
cp -f recovery_big.png powermenu.out/
cp -f fastboot.png powermenu.out/
cp -f fastboot_big.png powermenu.out/

cd $PATCHDIR/powermenu.out

$PATCHDIR/7za a -mx9 -tzip powermenu.zip *

cp -f $PATCHDIR/android.policy.jar.out/dist/android.policy.jar /system/framework/android.policy.jar

cp -f powermenu.zip /system/media/theme/default/powermenu

# DarthJabba9 - copy patched files to another place
cp -f $PATCHDIR/android.policy.jar.out/dist/android.policy.jar $PATCHDIR/$ANDROID_VER/patched/system/framework/android.policy.jar
cp -f powermenu.zip $PATCHDIR/$ANDROID_VER/patched/system/media/theme/default/powermenu
# DarthJabba9 - end() #3

cd $PATCHDIR

rm -rf android.policy.jar.out powermenu.out

exit

