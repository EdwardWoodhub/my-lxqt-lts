# 1. 继承红帽官方纯正 CentOS Stream 10 底座 (锁定纯正 .el10 内核)
FROM quay.io/centos-bootc/centos-bootc:stream10

# 2. 启用 EPEL 10 与 CRB 仓库 (KDE Plasma 6 基础源)
RUN dnf install -y 'https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm' && \
    dnf config-manager --set-enabled crb

# 3. 安装指定的 RPM 软件包
RUN dnf install -y \
    mesa-dri-drivers \
    xorg-x11-server-Xwayland \
    sddm \
    dbus-x11 \
    xdg-desktop-portal \
    xdg-user-dirs \
    plasma-workspace \
    plasma-desktop \
    kwin \
    polkit-kde \
    plasma-firewall-firewalld \
    dolphin \
    konsole \
    kate \
    firefox \
    spectacle \
    syncthing \
    git \
    htop \
    btop \
    flatpak \
    && dnf clean all

# 4. 配置默认启动目标为图形界面，并启用 SDDM 显示管理器
RUN systemctl set-default graphical.target && \
    systemctl enable sddm.service

# 5. 配置 Flathub 软件源与开机预装服务
RUN flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# 创建 Flatpak 首次开机自动安装脚本
RUN mkdir -p /usr/libexec/my-custom-setup && \
    cat <<'EOF' > /usr/libexec/my-custom-setup/install-flatpaks.sh
#!/usr/bin/env bash
set -e

FLATPAKS=(
  org.mozilla.firefox
  com.google.Chrome
  com.github.tchx84.Flatseal
  com.xnview.XnViewMP
  com.visualstudio.code
  net.nokyan.Resources
  io.missioncenter.MissionCenter
  io.github.peazip.PeaZip
)

for app in "${FLATPAKS[@]}"; do
  flatpak install --system -y --noninteractive flathub "$app" || true
done
EOF
    chmod +x /usr/libexec/my-custom-setup/install-flatpaks.sh

# 注册一次性预装 systemd 服务
RUN cat <<'EOF' > /etc/systemd/system/preinstall-flatpaks.service
[Unit]
Description=Pre-install default system Flatpaks
After=network-online.target
Wants=network-online.target
ConditionPathExists=!/var/lib/flatpaks-installed.stamp

[Service]
Type=oneshot
ExecStart=/usr/libexec/my-custom-setup/install-flatpaks.sh
ExecStartPost=/usr/bin/touch /var/lib/flatpaks-installed.stamp
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable preinstall-flatpaks.service
