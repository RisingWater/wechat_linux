FROM ubuntu:22.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:1 \
    RESOLUTION=1024x768x24 \
    LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8

# 设置时区为上海
ENV TZ=Asia/Shanghai

# 安装所有依赖（包括noVNC）
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    # X11和VNC
    xvfb \
    x11vnc \
    fluxbox \
    # 桌面环境依赖
    dbus-x11 \
    xorg \
    # noVNC (使用系统包)
    novnc \
    websockify \
    # 字体
    fonts-wqy-microhei \
    fonts-wqy-zenhei \
    fonts-noto-cjk \
    # 工具
    procps \
    net-tools

# 创建用户
RUN useradd -m -s /bin/bash wechat && \
    echo 'wechat:wechat' | chpasswd

RUN apt-get install -y \
    libxkbcommon-x11-0 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-render-util0 \
    libxcb-keysyms1

RUN apt-get install -y \
    locales \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# 生成中文locale
RUN locale-gen zh_CN.UTF-8 && \
    update-locale LANG=zh_CN.UTF-8

# 设置时区
RUN ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# 安装微信
COPY scripts/install-wechat.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/install-wechat.sh
RUN /usr/local/bin/install-wechat.sh

COPY scripts/start.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start.sh

# 设置工作目录
WORKDIR /home/wechat

# 暴露端口
EXPOSE 6080

# 启动脚本
CMD ["/usr/local/bin/start.sh"]
#CMD ["/bin/bash"]