#!/bin/bash
# 针对国内网络环境优化的 Clash 安装脚本
# 解决 GeoSite 下载超时问题

# shellcheck disable=SC2148
# shellcheck disable=SC1091
. script/common.sh >&/dev/null
. script/clashctl.sh >&/dev/null

# 国内网络环境配置
export CN_NETWORK=true

# 设置国内镜像源
_set_cn_mirrors() {
    # 使用 jsDelivr CDN 加速 GitHub 资源
    export URL_GH_PROXY='https://fastly.jsdelivr.net/gh/'
    
    # 国内 DNS 服务器
    export CN_DNS_SERVERS="223.5.5.5,119.29.29.29,114.114.114.114"
    
    _okcat '🇨🇳' '已启用国内网络优化配置'
}

# 预下载 GeoSite 数据文件
_predownload_geodata() {
    local geodata_dir="${CLASH_BASE_DIR}"
    mkdir -p "$geodata_dir"
    
    _okcat '⏳' '正在预下载 GeoSite 数据文件...'
    
    # 下载 GeoSite 数据文件到安装目录
    local geosite_url="https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geosite.dat"
    local geoip_url="https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geoip.dat"
    local mmdb_url="https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/country.mmdb"
    
    # 下载 GeoSite.dat
    curl \
        --progress-bar \
        --show-error \
        --insecure \
        --connect-timeout 30 \
        --max-time 120 \
        --retry 3 \
        --retry-delay 5 \
        --output "${geodata_dir}/GeoSite.dat" \
        "$geosite_url" || {
            _failcat '下载 GeoSite.dat 失败，尝试备用源...'
            curl \
                --progress-bar \
                --show-error \
                --insecure \
                --connect-timeout 30 \
                --max-time 120 \
                --retry 2 \
                --output "${geodata_dir}/GeoSite.dat" \
                "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geosite.dat"
        }
    
    # 下载 GeoIP.dat
    curl \
        --progress-bar \
        --show-error \
        --insecure \
        --connect-timeout 30 \
        --max-time 120 \
        --retry 3 \
        --retry-delay 5 \
        --output "${geodata_dir}/GeoIP.dat" \
        "$geoip_url" || {
            _failcat '下载 GeoIP.dat 失败，尝试备用源...'
            curl \
                --progress-bar \
                --show-error \
                --insecure \
                --connect-timeout 30 \
                --max-time 120 \
                --retry 2 \
                --output "${geodata_dir}/GeoIP.dat" \
                "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geoip.dat"
        }
    
    # 下载 Country.mmdb
    curl \
        --progress-bar \
        --show-error \
        --insecure \
        --connect-timeout 30 \
        --max-time 120 \
        --retry 3 \
        --retry-delay 5 \
        --output "${geodata_dir}/Country.mmdb" \
        "$mmdb_url" || {
            _failcat '下载 Country.mmdb 失败，使用内置文件...'
            # 使用内置的 Country.mmdb 文件
            [ -f "${RESOURCES_BASE_DIR}/Country.mmdb" ] && {
                cp "${RESOURCES_BASE_DIR}/Country.mmdb" "${geodata_dir}/Country.mmdb"
            }
        }
    
    _okcat '✅' 'GeoSite 数据文件预下载完成'
}

# 创建针对国内环境的 Mixin 配置
_create_cn_mixin() {
    cat > "${RESOURCES_CONFIG_MIXIN}" << 'EOF'
# 系统代理配置
system-proxy:
  enable: true

# Web 控制台配置
external-controller: "0.0.0.0:9090"
external-ui: public
secret:

# 代理服务器配置
allow-lan: false # 若开启务必设置用户验证以防暴露公网后被滥用
authentication:
  # - "username:password" # 用户验证（clashon 会自动填充验证信息）

# 自定义规则
rules:
  - DOMAIN,api64.ipify.org,DIRECT # 用于 clashui 获取真实公网 IP

# tun 配置
tun:
  enable: false
  stack: system
  auto-route: true
  auto-redir: true # clash
  auto-redirect: true # mihomo
  auto-detect-interface: true
  dns-hijack:
    - any:53
    - tcp://any:53
  strict-route: true
  exclude-interface:
    # - docker0
    # - podman0

# DNS 配置（针对国内环境优化）
dns:
  enable: true
  listen: 0.0.0.0:1053
  enhanced-mode: fake-ip
  nameserver:
    - 223.5.5.5      # 阿里云 DNS
    - 119.29.29.29   # 腾讯云 DNS
    - 114.114.114.114 # 114 DNS
    - 8.8.8.8        # Google DNS
  fallback:
    - 8.8.8.8
    - 1.1.1.1
  fallback-filter:
    geoip: true
    geoip-code: CN
    ipcidr:
      - 240.0.0.0/4

# GeoSite 和 GeoIP 数据源配置（解决国内下载超时问题）
geodata-mode: true
geodata-loader: memconservative
geo-auto-update: true
geo-update-interval: 24
geox-url:
  geoip: "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geoip.dat"
  geosite: "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geosite.dat"
  mmdb: "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/country.mmdb"

# 网络延迟优化
profile:
  store-selected: true
  store-fake-ip: false
EOF
    _okcat '✅' '已创建国内环境优化配置'
}

# 主安装流程
main() {
    _okcat '🚀' '开始安装 Clash（国内网络优化版）'
    
    # 设置国内镜像源
    _set_cn_mirrors
    
    # 环境验证
    _valid_env
    
    # 检查安装路径
    [ -d "$CLASH_BASE_DIR" ] && _error_quit "请先执行卸载脚本,以清除安装路径：$CLASH_BASE_DIR"
    
    # 获取内核
    _get_kernel
    
    # 安装二进制文件
    /usr/bin/install -D <(gzip -dc "$ZIP_KERNEL") "${RESOURCES_BIN_DIR}/$BIN_KERNEL_NAME"
    tar -xf "$ZIP_SUBCONVERTER" -C "$RESOURCES_BIN_DIR"
    tar -xf "$ZIP_YQ" -C "${RESOURCES_BIN_DIR}"
    # shellcheck disable=SC2086
    /bin/mv -f ${RESOURCES_BIN_DIR}/yq_* "${RESOURCES_BIN_DIR}/yq"
    
    # 设置二进制文件路径
    _set_bin "$RESOURCES_BIN_DIR"
    
    # 创建国内环境优化配置
    _create_cn_mixin
    
    # 验证或下载配置
    _valid_config "$RESOURCES_CONFIG" || {
        echo -n "$(_okcat '✈️ ' '输入订阅：')"
        read -r url
        _okcat '⏳' '正在下载...'
        _download_config "$RESOURCES_CONFIG" "$url" || _error_quit "下载失败: 请将配置内容写入 $RESOURCES_CONFIG 后重新安装"
        _valid_config "$RESOURCES_CONFIG" || _error_quit "配置无效，请检查配置：$RESOURCES_CONFIG，转换日志：$BIN_SUBCONVERTER_LOG"
    }
    _okcat '✅' '配置可用'
    
    # 创建安装目录
    mkdir "$CLASH_BASE_DIR"
    echo "$url" >"$CLASH_CONFIG_URL"
    
    # 复制文件
    /bin/cp -rf "$SCRIPT_BASE_DIR" "$CLASH_BASE_DIR"
    /bin/ls "$RESOURCES_BASE_DIR" | grep -Ev 'zip|png' | xargs -I {} /bin/cp -rf "${RESOURCES_BASE_DIR}/{}" "$CLASH_BASE_DIR"
    tar -xf "$ZIP_UI" -C "$CLASH_BASE_DIR"
    
    # 预下载 GeoSite 数据文件
    _predownload_geodata
    
    # 设置系统服务
    _set_rc
    _set_bin
    _merge_config_restart
    
    # 创建 systemd 服务
    cat <<EOF >"/etc/systemd/system/${BIN_KERNEL_NAME}.service"
[Unit]
Description=$BIN_KERNEL_NAME Daemon, A[nother] Clash Kernel.

[Service]
Type=simple
Restart=always
ExecStart=${BIN_KERNEL} -d ${CLASH_BASE_DIR} -f ${CLASH_CONFIG_RUNTIME}

[Install]
WantedBy=multi-user.target
EOF
    
    # 启用服务
    systemctl daemon-reload
    systemctl enable "$BIN_KERNEL_NAME" >&/dev/null || _failcat '💥' "设置自启失败" && _okcat '🚀' "已设置开机自启"
    
    # 显示控制面板
    clashui
    _okcat '🎉' 'enjoy 🎉'
    _okcat '🇨🇳' '国内网络环境优化安装完成！'
    clash
    # shellcheck disable=SC2016
    _quit
}

# 执行主函数
main "$@"