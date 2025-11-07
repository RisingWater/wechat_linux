# WeChat Linux Docker

基于 Docker 的微信 Linux 版容器化解决方案，使用 noVNC 通过浏览器访问微信界面。
后续会基于此Docker可以开发微信机器人、微信聊天记录备份等功能。

## 快速开始

### 前提条件

- 安装Docker

### 克隆项目

```bash
git clone https://github.com/RisingWater/wechat_linux
cd wechat_linux
```

### 构建镜像

```bash
docker build ./ -t wechat-linux:latest
```

### 运行容器

```bash
docker run -d -it -p 6080:6080 \
  -v $HOME/wechat_config:/home/wechat/.xwechat \
  -v $HOME/wechat_files:/home/wechat/xwechat_files \
  --name wechat \
  wechat-linux:latest
```

## 访问方式

### Web 浏览器访问
打开浏览器访问：http://localhost:6080

## 数据持久化

容器使用以下卷挂载来保存数据：

| 宿主机目录 | 容器内目录 | 说明 |
|-----------|------------|------|
| `$HOME/wechat_config` | `/home/wechat/.xwechat` | 微信配置和聊天记录 |
| `$HOME/wechat_files` | `/home/wechat/xwechat_files` | 微信文件存储 |


## 日志文件位置

- 容器日志：`docker logs wechat`
- 微信应用日志：`/var/log/wechat/wechat.log`
- X11 服务日志：`/var/log/xvfb.log`
- VNC 服务日志：`/var/log/x11vnc.log`

## 项目结构

```
wechat_linux/
├── Dockerfile                 # Docker 构建文件
├── scripts/                   # 工具脚本
│   ├── start.sh              # 启动脚本
│   └── install-wechat.sh     # 微信安装脚本
└── README.md                 # 说明文档
```

## 组件使用

- **基础镜像**: Ubuntu 22.04
- **桌面环境**: Fluxbox
- **远程访问**: X11VNC + noVNC
- **显示服务**: Xvfb

## 许可证

本项目基于 MIT 许可证开源。

## 贡献

欢迎提交 Issue 和 Pull Request！

## 免责声明

本项目仅用于技术学习和研究目的。微信是腾讯公司的注册商标，相关版权归腾讯公司所有。
