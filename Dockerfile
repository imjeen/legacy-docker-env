FROM node:16-bullseye

# 安装图片处理库所需的系统依赖
RUN apt-get update && apt-get install -y \
    build-essential \
    libpng-dev \
    libjpeg-dev \
    libtiff-dev \
    autoconf \
    automake \
    libtool \
    nasm \
    pkg-config \
    cmake \
    # 其他可能需要的依赖
    g++ \
    make \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 复制 package.json 和 package-lock.json
COPY package*.json ./
# 安装 npm 依赖
# RUN npm install

# 复制项目文件
COPY . .

# 暴露应用端口
EXPOSE 8080

# 启动命令（可以根据你的项目调整）
# CMD ["npm", "install"]