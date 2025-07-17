# Clash for Linux 国内网络环境安装指南

## 问题描述

在国内VPS上安装Clash时，经常遇到以下错误：

```
ERRO[2025-07-17T13:30:44.923412634+08:00] can't initial GeoSite: can't download GeoSite.dat: context deadline exceeded
```

这是由于国内网络环境访问GitHub等海外资源时网络不稳定导致的GeoSite数据文件下载超时问题。

## 解决方案

本项目已针对国内网络环境进行了优化，主要包括：

### 1. 配置文件优化（mixin.yaml）

已修改 `resources/mixin.yaml` 文件，添加了以下优化：

- **国内DNS服务器**：优先使用阿里云DNS、腾讯云DNS等国内服务器
- **GeoSite数据源**：使用jsDelivr CDN加速GitHub资源访问
- **网络超时优化**：增加了重试机制和超时时间

### 2. 脚本优化（common.sh）

修改了 `script/common.sh` 中的下载函数：

- 增加重试次数：从1次增加到3次
- 延长超时时间：连接超时从4秒增加到15秒，最大下载时间60秒
- 添加重试延迟：每次重试间隔2秒

### 3. 国内环境专用安装脚本（install-cn.sh）

创建了专门针对国内网络环境的安装脚本，包含：

- 预下载GeoSite数据文件
- 使用国内镜像源
- 网络连接优化配置

## 使用方法

### 方法一：使用优化后的原版脚本

1. 将整个项目上传到您的国内VPS
2. 直接使用原版安装脚本（已经过优化）：

```bash
sudo bash install.sh
```

### 方法二：使用国内环境专用脚本

1. 将整个项目上传到您的国内VPS
2. 使用国内环境专用安装脚本：

```bash
sudo bash install-cn.sh
```

### 方法三：手动预下载GeoSite文件（推荐）

如果仍然遇到下载问题，可以手动预下载GeoSite文件：

```bash
# 创建临时目录
mkdir -p /tmp/geodata

# 下载GeoSite数据文件
curl -L -o /tmp/geodata/GeoSite.dat "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geosite.dat"
curl -L -o /tmp/geodata/GeoIP.dat "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geoip.dat"
curl -L -o /tmp/geodata/Country.mmdb "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/country.mmdb"

# 运行安装脚本
sudo bash install.sh

# 安装完成后，将预下载的文件复制到Clash目录
sudo cp /tmp/geodata/* /opt/clash/
```

## 配置说明

### DNS配置优化

新的DNS配置优先使用国内DNS服务器：

```yaml
dns:
  nameserver:
    - 223.5.5.5      # 阿里云DNS
    - 119.29.29.29   # 腾讯云DNS  
    - 114.114.114.114 # 114DNS
    - 8.8.8.8        # Google DNS（备用）
```

### GeoSite数据源配置

使用jsDelivr CDN加速GitHub资源：

```yaml
geox-url:
  geoip: "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geoip.dat"
  geosite: "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geosite.dat"
  mmdb: "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/country.mmdb"
```

## 故障排除

### 如果仍然遇到下载超时

1. **检查网络连接**：
   ```bash
   ping fastly.jsdelivr.net
   ```

2. **手动测试下载**：
   ```bash
   curl -I "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geosite.dat"
   ```

3. **使用备用CDN**：
   如果jsDelivr无法访问，可以尝试修改 `mixin.yaml` 中的URL为：
   ```yaml
   geox-url:
     geosite: "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geosite.dat"
   ```

### 如果启动后仍然报错

1. **查看详细日志**：
   ```bash
   sudo journalctl -u mihomo -f
   ```

2. **检查配置文件**：
   ```bash
   sudo mihomo -d /opt/clash -f /opt/clash/runtime.yaml -t
   ```

3. **重新下载GeoSite文件**：
   ```bash
   sudo rm -f /opt/clash/GeoSite.dat /opt/clash/GeoIP.dat
   sudo systemctl restart mihomo
   ```

## 注意事项

1. **防火墙设置**：确保VPS防火墙开放了Clash所需端口（默认7890、9090）
2. **系统权限**：安装脚本需要root权限执行
3. **网络环境**：如果VPS网络环境特殊，可能需要根据实际情况调整DNS和代理设置

## 更新订阅

安装完成后，可以使用以下命令更新订阅：

```bash
clash update [订阅URL]
```

如果更新过程中遇到网络问题，配置会自动回滚到上一个可用状态。

---

通过以上优化，应该能够解决国内VPS上Clash安装时的GeoSite下载超时问题。如果仍然遇到问题，请检查VPS的网络环境或联系VPS提供商。