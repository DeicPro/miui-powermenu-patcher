echo "Updating package lists..."
apt update
echo "Installing wget..."
echo y | apt install wget
echo "Downloading bin.zip"
wget --no-check-certificate https://raw.githubusercontent.com/DeicPro/miui-powermenu-patcher/bin/bin.zip
echo "Building script..."
base64 bin.zip >> miui-powermenu-patcher.sh
echo "Script built: $(pwd)/miui-powermenu-patcher.sh"
