# miui-powermenu-patcher
A script to get reboot to recovery &amp; fastboot from power menu

Build from Linux or from Android with Termux:
```
apt update && echo y | apt install git wget
git clone https://github.com/DeicPro/miui-powermenu-patcher.git
cd miui-powermenu-patcher
wget --no-check-certificate https://raw.githubusercontent.com/DeicPro/miui-powermenu-patcher/bin/bin.zip
base64 bin.zip >> miui-powermenu-patcher.sh
echo "File $(pwd)/miui-powermenu-patcher.sh done"
```