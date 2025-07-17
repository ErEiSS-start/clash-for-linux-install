#!/bin/bash
# 临时解决 GeoSite 下载超时问题的快速修复脚本

echo "🔧 正在修复 GeoSite 下载超时问题..."

# 创建必要的目录
mkdir -p ./resources

# 下载 GeoSite 数据文件到 resources 目录
echo "⏳ 正在下载 GeoSite.dat..."
curl -L --progress-bar --connect-timeout 30 --max-time 120 --retry 3 \
    -o "./resources/GeoSite.dat" \
    "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geosite.dat" || {
    echo "📡 尝试备用 CDN..."
    curl -L --progress-bar --connect-timeout 30 --max-time 120 --retry 2 \
        -o "./resources/GeoSite.dat" \
        "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geosite.dat"
}

echo "⏳ 正在下载 GeoIP.dat..."
curl -L --progress-bar --connect-timeout 30 --max-time 120 --retry 3 \
    -o "./resources/GeoIP.dat" \
    "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geoip.dat" || {
    echo "📡 尝试备用 CDN..."
    curl -L --progress-bar --connect-timeout 30 --max-time 120 --retry 2 \
        -o "./resources/GeoIP.dat" \
        "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geoip.dat"
}

echo "⏳ 正在下载 Country.mmdb..."
curl -L --progress-bar --connect-timeout 30 --max-time 120 --retry 3 \
    -o "./resources/Country.mmdb" \
    "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/country.mmdb" || {
    echo "📡 尝试备用 CDN..."  
    curl -L --progress-bar --connect-timeout 30 --max-time 120 --retry 2 \
        -o "./resources/Country.mmdb" \
        "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/country.mmdb"
}

# 检查下载结果
if [ -f "./resources/GeoSite.dat" ] && [ -f "./resources/GeoIP.dat" ]; then
    echo "✅ GeoSite 数据文件下载完成！"
    echo "📁 文件已保存到 ./resources/ 目录"
    echo ""
    echo "现在可以重新运行安装脚本："
    echo "sudo bash install.sh"
else
    echo "❌ 部分文件下载失败，请检查网络连接"
    echo "您可以尝试以下解决方案："
    echo "1. 手动下载文件放到 resources 目录"
    echo "2. 使用代理网络重新运行此脚本"
    echo "3. 联系网络管理员检查防火墙设置"
fi