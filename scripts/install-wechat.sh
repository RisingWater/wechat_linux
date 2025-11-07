#!/bin/bash

# 微信官方Linux版下载链接（请根据实际情况更新）
WECHAT_DEB_URL="https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.deb"
WECHAT_DEB_FILE="/tmp/WeChatLinux.deb"

echo "正在安装微信Linux版..."

# 下载微信deb包
echo "正在下载微信..."
if wget -O "$WECHAT_DEB_FILE" "$WECHAT_DEB_URL"; then
    echo "下载完成"
else
    echo "下载失败，请检查网络连接或URL是否有效"
    exit 1
fi

# 安装微信
echo "正在安装微信..."
dpkg -i "$WECHAT_DEB_FILE"

# 清理临时文件
rm -f "$WECHAT_DEB_FILE"

# 设置权限
chown -R wechat:wechat /home/wechat

echo "微信安装完成"