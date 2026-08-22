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
    fastfetch \
    spectacle \
    syncthing \
    git \
    htop \
    btop \
    flatpak \
    kscreen \
    open-vm-tools \
    open-vm-tools-desktop \
    && dnf clean all

# 4. 配置默认启动目标为图形界面，并启用 SDDM 显示管理器
RUN systemctl set-default graphical.target && \
    systemctl enable sddm.service

# 启用服务开机自启（在容器构建阶段生效）
RUN systemctl enable vmtoolsd.service

# 5. 配置 Flathub 软件源
RUN flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# 6. 生成 Flatpak 开机预装脚本 (已加入坚果云)
RUN mkdir -p /usr/libexec/my-custom-setup && \
    printf '%s\n' \
      '#!/usr/bin/env bash' \
      'set -e' \
      'FLATPAKS=(' \
      '  org.mozilla.firefox' \
      '  com.google.Chrome' \
      '  com.github.tchx84.Flatseal' \
      '  com.xnview.XnViewMP' \
      '  com.visualstudio.code' \
      '  net.nokyan.Resources' \
      '  io.missioncenter.MissionCenter' \
      '  io.github.peazip.PeaZip' \
      '  com.jianguoyun.Nutstore' \
      ')' \
      'for app in "${FLATPAKS[@]}"; do' \
      '  flatpak install --system -y --noninteractive flathub "$app" || true' \
      'done' \
      > /usr/libexec/my-custom-setup/install-flatpaks.sh && \
    chmod +x /usr/libexec/my-custom-setup/install-flatpaks.sh

# 7. 注册开机一次性预装 systemd 服务
RUN printf '%s\n' \
      '[Unit]' \
      'Description=Pre-install default system Flatpaks' \
      'After=network-online.target' \
      'Wants=network-online.target' \
      'ConditionPathExists=!/var/lib/flatpaks-installed.stamp' \
      '' \
      '[Service]' \
      'Type=oneshot' \
      'ExecStart=/usr/libexec/my-custom-setup/install-flatpaks.sh' \
      'ExecStartPost=/usr/bin/touch /var/lib/flatpaks-installed.stamp' \
      'RemainAfterExit=yes' \
      '' \
      '[Install]' \
      'WantedBy=multi-user.target' \
      > /etc/systemd/system/preinstall-flatpaks.service && \
    systemctl enable preinstall-flatpaks.service
