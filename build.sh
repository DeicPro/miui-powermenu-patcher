echo "Downloading dependencies..."
wget --no-check-certificate https://raw.githubusercontent.com/DeicPro/miui-powermenu-patcher/bin/wget.zip
echo "Building script..."
base64 wget.zip >> miui-powermenu-patcher.sh
echo "Script built: $(pwd)/miui-powermenu-patcher.sh"
