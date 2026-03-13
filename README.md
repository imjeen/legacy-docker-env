# 在旧项目中搭建 Docker 开发环境

## 背景

项目中直接或间接使用了 `mozjpeg`、`pngquant-bin` 等图片处理库，这些库依赖系统级组件，导致项目在本地无法直接运行。本文提供完整的 Docker 开发环境配置方案来解决这一问题。

## 为什么需要 Docker？

### 根本原因

这些图片处理库的核心功能并非由 JavaScript 实现，而是依赖 **C/C++ 编写的原生库**来提供高性能的图像编解码能力。因此，它们需要在系统层面安装特定的编译工具和依赖库。

### 系统依赖的必要性

以 `pngquant-bin` 为例，当安装时如果找不到适合当前操作系统（Linux/macOS/Windows）的**预编译二进制文件**，它会尝试从**源代码编译**，这时就需要以下系统组件：

| 依赖类型         | 作用                          | 典型示例                    |
| ---------------- | ----------------------------- | --------------------------- |
| **编译工具链**   | 将 C/C++ 源码编译为二进制文件 | `gcc`、`g++`、`make`        |
| **开发头文件**   | 编译时引用的库声明            | `libpng-dev`、`libjpeg-dev` |
| **平台特定工具** | 性能优化（如 SIMD 指令）      | `nasm`（用于 `mozjpeg`）    |

## 类似依赖原生库的 Node.js 模块

许多高性能 Node.js 模块都有相同的系统依赖需求：

| 模块            | 功能                             | 常见系统依赖                                 |
| :-------------- | :------------------------------- | :------------------------------------------- |
| **sharp**       | 高性能图片处理                   | `libvips`、`libjpeg-turbo`、`libpng`、`nasm` |
| **node-canvas** | Canvas 实现                      | `Cairo`、`Pango`、`libjpeg`、`libgif`        |
| **node-gyp**    | 原生插件编译工具                 | Python、`make`、`g++`、Windows VC++          |
| **bcrypt**      | 密码哈希                         | `g++`、`make`、Python                        |
| **\*-bin 类库** | 如 `jpegtran-bin`、`optipng-bin` | 依赖对应的原始工具库                         |

## Docker 环境配置

### 基础使用命令

```bash
# 启动服务
docker-compose up        # 前台运行
docker-compose up -d     # 后台运行

# 查看日志
docker-compose logs -f

# 进入容器内部
docker-compose exec app /bin/bash

# 停止服务
docker-compose down

# 重新构建（修改依赖后）
docker-compose up --build           # 增量构建
docker-compose build --no-cache      # 完全重新构建
```

### 临时容器与端口访问

```bash
# 进入临时容器（适合执行一次性命令）
docker-compose run --rm app bash

# 如需从宿主机访问临时容器的端口
docker-compose run --rm -P app bash              # 自动映射端口
docker-compose run --rm -p 8080:8080 app bash    # 指定端口映射

# 注意：使用 run 命令前，建议先执行 docker-compose down 避免端口冲突
```

### 特殊配置说明

如果项目使用 `sharp` 等库，可能需要在 `package.json` 中指定目标平台：

```json
{
  "config": {
    "sharp": {
      "binaries": ["linux-x64"]
    }
  }
}
```

## 常见问题

### node_modules 的处理

在 Docker 环境中，建议将 `node_modules` 放在容器内部，避免与宿主机环境冲突。可通过 volumes 配置实现：

```yaml
volumes:
  - .:/app # 挂载源码
  - /app/node_modules # 保留容器内 node_modules
```

### 权限问题

如果遇到文件权限问题，可以在 Dockerfile 中创建与宿主机 UID/GID 匹配的用户：

```dockerfile
ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID nodejs && useradd -m -u $UID -g $GID nodejs
USER nodejs
```

---

通过这套 Docker 方案，你可以：

- ✅ 避免本地环境配置的复杂性
- ✅ 保证所有开发成员使用一致的环境
- ✅ 轻松处理各类系统级依赖问题
