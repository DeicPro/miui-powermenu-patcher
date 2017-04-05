#!/system/bin/sh
# by xda@Deic

SCRIPT_DIR=$0
PATCHDIR=/data/miui-powermenu-patcher
SMALIFILE=$PATCHDIR/android.policy.jar.out/smali/com/android/internal/policy/impl/MiuiGlobalActions\$1.smali
MANIFESTFILE=$PATCHDIR/powermenu.out/manifest.xml
SMALI_N=1
MANIFEST_N=7
STRINGS_N=2
BIN_UNZIP=0
START_LINE=392

# busybox aliases (in case of no symlinks)
alias basename="busybox basename"
alias dirname="busybox dirname"
alias tail="busybox tail"
alias base64="busybox base64"
alias unzip="busybox unzip"
alias sed="busybox sed"
alias awk="busybox awk"

# get current Android release for backup of stock files
ANDROID_VER=$(getprop "ro.build.version.incremental")
[ -z "$ANDROID_VER" ] && ANDROID_VER=old_android

# display message and terminate script (optionally supply exit code)
Abort()
{
  echo "$1"
  exit $2
} # Abort()

# return location of embedded code + 1 - or zero if code not found
FindEmbeddedCode()
{
 local CODE="#embedded file below"
 local N=$(grep -n -x "$CODE" $SCRIPT_DIR)
 [ -n "$N" ] && {
    local n=${N%%:*} # strip everything from ":" onwards
    local c=1 # increment count
    echo $(( n + c ))
 } || echo 0
} # FindEmbeddedCode()

# return the full path of the running script
RunningProg()
{
local n=$(basename $0)
local d=$(dirname $0)
  [ "$d" = "." ] && echo $PWD/$n || echo $0
} # RunningProg()

# backup the stock files (if not already backed up)
Backup_StockFiles()
{
  # create dirs for stock backup
  mkdir -p $PATCHDIR/$ANDROID_VER/stock/system/framework/
  [ ! -d $PATCHDIR/$ANDROID_VER/stock/system/framework/ ] && {
      echo "Error creating directory: $PATCHDIR/$ANDROID_VER/stock/system/framework/"
      return  
  }
  
  mkdir -p $PATCHDIR/$ANDROID_VER/stock/system/media/theme/default/
  [ ! -d $PATCHDIR/$ANDROID_VER/stock/system/media/theme/default/ ] && {
      echo "Error creating directory: $PATCHDIR/$ANDROID_VER/stock/system/media/theme/default/"
      return  
  }

  # backup 
  echo "Backing up stock files (if not already backed up) ..."
  [ ! -f $PATCHDIR/$ANDROID_VER/stock/system/framework/android.policy.jar ] && {
      cp -af /system/framework/android.policy.jar $PATCHDIR/$ANDROID_VER/stock/system/framework/
  }

  [ ! -f $PATCHDIR/$ANDROID_VER/stock/system/media/theme/default/powermenu ] && {
      cp -af /system/media/theme/default/powermenu $PATCHDIR/$ANDROID_VER/stock/system/media/theme/default/
  }
  
  echo "Finished backing up stock files."
  
} # Backup_StockFiles()

# backup the patched files
Backup_PatchedFiles()
{

   [ ! -d $PATCHDIR/powermenu.out ] && {
       echo "Invalid directory: $PATCHDIR/powermenu.out"
       return   
   }
   
   mkdir -p $PATCHDIR/$ANDROID_VER/patched/system/framework/
   [ ! -d $PATCHDIR/$ANDROID_VER/patched/system/framework/ ] && {
       echo "Error creating directory: $PATCHDIR/$ANDROID_VER/patched/system/framework/"
       return   
   }
   
   mkdir -p $PATCHDIR/$ANDROID_VER/patched/system/media/theme/default/
   [ ! -d $PATCHDIR/$ANDROID_VER/patched/system/media/theme/default/ ] && {
       echo "Error creating directory: $PATCHDIR/$ANDROID_VER/patched/system/media/theme/default/"
       return   
   }

   echo "Backing up the patched files..."
   local xdir=$(pwd)
   cd $PATCHDIR/powermenu.out
   cp -f $PATCHDIR/android.policy.jar.out/dist/android.policy.jar $PATCHDIR/$ANDROID_VER/patched/system/framework/android.policy.jar
   cp -f powermenu.zip $PATCHDIR/$ANDROID_VER/patched/system/media/theme/default/powermenu
   cd $xdir
   echo "Finished backing up the patched files..."

} # Backup_PatchedFiles()

# restore backup - either of stock, or already-completed patch
# no argument = restore backed up stock files
# send "patched" to this function to choose the already-completed patch
Restore_Backup()
{
  local BDIR="stock"
  [ "$1" = "patched" ] && BDIR=$1
  
  # some error checking
  [ ! -d $PATCHDIR ] && {
      echo "Invalid directory: \"$PATCHDIR\""
      return
  }
  
  # check for files - restore all, or nothing
  [ ! -f $PATCHDIR/$ANDROID_VER/$BDIR/system/framework/android.policy.jar ] && {
      echo "No android.policy.jar $BDIR backup"
      return
  }
  
  [ ! -f $PATCHDIR/$ANDROID_VER/$BDIR/system/media/theme/default/powermenu ] && {
      echo "No powermenu $BDIR backup"
      return
  }

  # if we get here, all relevant backup files exist
  echo "Mounting system (rw)..."
  mount -w -o remount /system

  echo "Restoring $BDIR files ..."
  cp -af $PATCHDIR/$ANDROID_VER/$BDIR/system/framework/android.policy.jar /system/framework/android.policy.jar
  cp -af $PATCHDIR/$ANDROID_VER/$BDIR/system/media/theme/default/powermenu /system/media/theme/default/powermenu

  echo "Mounting system (ro)..."
  mount -r -o remount /system

  echo "Finished restoring $BDIR files"
} # Restore_Backup()

patch_msg() 
{
    [ "$FIRST_C" ] && COUNT=$(($COUNT+1)) || { FILE_I=$1; FILE_N=$2; COUNT=0; }

    echo "Patching $FILE_I $COUNT/$FILE_N..."

    FIRST_C=1

    [ "$COUNT" == "$FILE_N" ] && unset FIRST_C
} # patch_msg()

# the main function to patch the powermenu
Patch_PowerMenu()
{
echo "Creating directories..."
mkdir -p $PATCHDIR

# some error checking
[ ! -d $PATCHDIR ] && Abort "Error creating \"$PATCHDIR\"" "1"
cd $PATCHDIR
echo "" > $PATCHDIR/miui-powermenu-patcher.log

# DarthJabba9; backup stock files (if not already backed up)
Backup_StockFiles
# DarthJabba9 - end()

# continue 
[ -f $PATCHDIR/wget ] || {
    # line where embedded file code start
    echo "Extracting embedded data..."
    NEW_TAIL="-n"
    # compatibility workarround with older version of tail
    tail $NEW_TAIL +1 "$SCRIPT_DIR" > /dev/null 2> /dev/null || NEW_TAIL=""
    tail $NEW_TAIL +$START_LINE "$SCRIPT_DIR" | base64 -d > $PATCHDIR/wget.zip
    unzip -o $PATCHDIR/wget.zip wget >> $PATCHDIR/miui-powermenu-patcher.log 2>&1
    rm -f $PATCHDIR/wget.zip
    chmod 755 $PATCHDIR/wget
}

# DarthJabba9 - check for files or separate bin.zip
[ ! -x $PATCHDIR/openjdk/bin/java ] || [ ! -d $PATCHDIR/openjdk/lib/arm ] && {
    BIN_ZIP=/storage/sdcard1/bin.zip
    [ -f $BIN_ZIP ] && {
        echo "Extracting environment from existing bin.zip..."
        unzip -o $BIN_ZIP "*" >> $PATCHDIR/miui-powermenu-patcher.log 2>&1
        chmod -R 755 $PATCHDIR
    }
}

[ -x $PATCHDIR/openjdk/bin/java ] && [ -d $PATCHDIR/openjdk/lib/arm ] && {
    BIN_UNZIP=1
}
# DarthJabba9 - end()

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
    source $PATCHDIR/patch.sh
}

## decompile
echo "Preparing environment..."
[ ! -f /data/app/per.pqy.apktool*/*.apk ] && {
    mkdir -p /data/data/per.pqy.apktool/apktool/openjdk/lib
    cp -f openjdk/lib/ld.so /data/data/per.pqy.apktool/apktool/openjdk/lib/ld.so
    chmod -R 755 /data/data/per.pqy.apktool
}

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
Backup_PatchedFiles
# DarthJabba9 - end()

cd $PATCHDIR

rm -rf android.policy.jar.out powermenu.out
rm -f android.policy.jar powermenu

echo "Finished patching the stock powermenu"
echo

} # Patch_PowerMenu()

# display a menu so the user can choose
Show_Menu()
{
    PS3='Select: '
    local Item1="Patch the stock powermenu"
    local Item2="Backup the stock powermenu"
    local Item3="Restore backup (Stock)"
    local Item4="Restore backup (previously patched)"
    local Item5="Quit"
    options=("$Item1" "$Item2" "$Item3" "$Item4" "$Item5")

    while :; do
        select opt in "${options[@]}"; do
            case $opt in
                "$Item1") Patch_PowerMenu; echo;;
                "$Item2") Backup_StockFiles; echo;;
                "$Item3") Restore_Backup "stock"; echo;;
                "$Item4") Restore_Backup "patched"; echo;;
                "$Item5") exit;;
                *) echo "Invalid option";;
            esac
            break
        done
    done
} # Show_Menu()

#**** Main() ****
  SCRIPT_DIR=$(RunningProg)

  # allow user to supply patchdir from command line, with "-d <dir>"
  [ "$1" = "-d" ] && [ -n "$2" ] && PATCHDIR=$2

  tmp=$(FindEmbeddedCode)
  [ ! "$tmp" = "0" ] && START_LINE=$tmp

  # display the menu
  Show_Menu

  exit # just in case!
#embedded file below
