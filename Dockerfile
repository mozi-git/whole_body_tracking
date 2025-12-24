# 使用指定的基础镜像
FROM nvidia/cuda:12.2.2-devel-ubuntu22.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    ISAACSIM_PATH=/isaac-sim \
    # WANDB配置
    WANDB_ENTITY=mrockw520-personal

# 更新包管理器并安装系统依赖 - 包括Python 3.10
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    cmake \
    libssl-dev \
    libffi-dev \
    libgl1-mesa-glx \
    libgl1-mesa-dri \
    libglew-dev \
    libosmesa6-dev \
    patchelf \
    x11-apps \
    mesa-utils \
    # 安装Python 3.10和相关工具
    python3.10 \
    python3.10-dev \
    python3.10-venv \
    python3-pip \
    python3-setuptools \
    vim \
    ncurses-term \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    /var/cache/apt/archives/* \
    /tmp/* \
    /var/tmp/*

# 设置Python 3.10为默认python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1

# 创建工作目录
WORKDIR /workspace

# 升级pip并设置pip配置
RUN python -m pip install --upgrade pip \
    && pip config set global.cache-dir false

# 安装PyTorch (CUDA 12版本) - 使用no-cache-dir减少磁盘占用
RUN pip install --no-cache-dir torch==2.5.1 torchvision==0.20.1 --index-url https://download.pytorch.org/whl/cu121

# 安装Isaac Sim (接受EULA) 
RUN pip install 'isaacsim[all,extscache]==4.5.0' --extra-index-url https://pypi.nvidia.com \
    && echo 'y' | isaacsim --help > /dev/null 2>&1 || true 

# 克隆Isaac Lab仓库并切换到指定版本
RUN git clone --depth 1 --branch release/2.1.0 https://github.com/isaac-sim/IsaacLab.git /workspace/IsaacLab

# 安装Isaac Lab依赖
WORKDIR /workspace/IsaacLab
ENV TERM=xterm
RUN ./isaaclab.sh --install

# 安装wandb和其他可选依赖（按需安装）
RUN pip install --no-cache-dir wandb

# 清理不必要的文件
RUN apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/* \
    /root/.cache/pip/*


# 设置默认命令
CMD ["/usr/local/bin/start.sh"]