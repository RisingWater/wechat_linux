#!/bin/bash

# 设置显示
export DISPLAY=${DISPLAY:-:1}
export RESOLUTION=${RESOLUTION:-1024x768x24}
export LANG=zh_CN.UTF-8
export LANGUAGE=zh_CN:zh
export LC_ALL=zh_CN.UTF-8

echo "设置语言环境: $LANG"
echo "设置 DISPLAY: $DISPLAY"

# 检查locale设置
echo "当前locale设置:"
locale

# 创建日志目录并设置权限
mkdir -p /var/log/wechat
chown wechat:wechat /var/log/wechat
chmod 755 /var/log/wechat

chown -R wechat:wechat /home/wechat/.xwechat
chmod -R 755 /home/wechat/.xwechat

chown -R wechat:wechat /home/wechat/xwechat_files
chmod -R 755 /home/wechat/xwechat_files

# 设置noVNC默认页面为vnc.html
if [ -f "/usr/share/novnc/vnc_lite.html" ]; then
    # 备份原文件
    cp /usr/share/novnc/vnc_lite.html /usr/share/novnc/vnc_lite.html.backup
    # 创建指向vnc.html的符号链接
    ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html
    ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/vnc_lite.html
    echo "已设置noVNC默认页面为vnc.html"
fi

# 清理之前的X Server进程
pkill Xvfb 2>/dev/null || true
pkill x11vnc 2>/dev/null || true

# 启动DBus
mkdir -p /var/run/dbus
dbus-daemon --config-file=/usr/share/dbus-1/system.conf --print-address &

# 启动Xvfb (虚拟X Server)
echo "启动Xvfb..."
Xvfb $DISPLAY -screen 0 $RESOLUTION -ac +extension GLX +render -noreset > /var/log/xvfb.log 2>&1 &
XVFB_PID=$!

# 等待X Server启动
sleep 2

# 检查Xvfb是否启动成功
if ! ps -p $XVFB_PID > /dev/null; then
    echo "错误: Xvfb启动失败"
    cat /var/log/xvfb.log
    exit 1
fi

echo "Xvfb启动成功 (PID: $XVFB_PID)"

# 设置X Authority
export XAUTHORITY=/tmp/.xauthority
xauth generate $DISPLAY . trusted > /dev/null 2>&1

# 启动fluxbox窗口管理器
echo "启动fluxbox..."
fluxbox > /var/log/fluxbox.log 2>&1 &
sleep 1

# 启动x11vnc (将X Server共享出去)
echo "启动x11vnc..."
x11vnc -display $DISPLAY -forever -shared -nopw -listen 0.0.0.0 -xkb > /var/log/x11vnc.log 2>&1 &
X11VNC_PID=$!
sleep 2

# 启动noVNC
echo "启动noVNC..."
websockify --web /usr/share/novnc 6080 localhost:5900 > /var/log/novnc.log 2>&1 &
NOVNC_PID=$!

# 等待服务启动
sleep 3

echo "检查服务状态:"
echo "- Xvfb: $(ps -p $XVFB_PID > /dev/null && echo '运行中' || echo '已停止')"
echo "- x11vnc: $(ps -p $X11VNC_PID > /dev/null && echo '运行中' || echo '已停止')"
echo "- noVNC: $(ps -p $NOVNC_PID > /dev/null && echo '运行中' || echo '已停止')"

# 等待X Server完全就绪
sleep 5

# 启动微信（使用wechat用户，设置正确的DISPLAY）
echo "启动微信..."
su - wechat -c "export DISPLAY=$DISPLAY && cd /tmp && wechat > /var/log/wechat/wechat.log 2>&1" &
WECHAT_PID=$!

echo "等待微信启动..."
sleep 10

# 检查进程状态
echo "进程状态检查:"
ps aux | grep -E "(wechat|Xvfb|x11vnc)" | grep -v grep

# 检查X Client连接
echo "X Client连接:"
netstat -tlnp | grep -E "(6080)"

echo "=========================================="
echo "服务启动完成!"
echo "Web访问: http://localhost:6080/vnc.html"
echo "VNC客户端: localhost:5900"
echo "=========================================="

# 监控进程
while true; do
    # 检查Xvfb
    if ! ps -p $XVFB_PID > /dev/null; then
        echo "Xvfb已停止，重启..."
        Xvfb $DISPLAY -screen 0 $RESOLUTION -ac +extension GLX +render -noreset > /var/log/xvfb.log 2>&1 &
        XVFB_PID=$!
        sleep 2
    fi
    
    # 检查x11vnc
    if ! ps -p $X11VNC_PID > /dev/null; then
        echo "x11vnc已停止，重启..."
        x11vnc -display $DISPLAY -forever -shared -nopw -listen 0.0.0.0 -xkb > /var/log/x11vnc.log 2>&1 &
        X11VNC_PID=$!
        sleep 2
    fi
    
    # 检查微信进程
    if ! ps -p $WECHAT_PID > /dev/null 2>/dev/null; then
        echo "微信进程已停止，尝试重新启动..."
        su - wechat -c "export DISPLAY=$DISPLAY && cd /tmp && wechat > /var/log/wechat/wechat.log 2>&1" &
        WECHAT_PID=$!
        echo "微信重启完成 (PID: $WECHAT_PID)"
    fi
    
    sleep 30
done