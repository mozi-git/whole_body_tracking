# 使用指定的基础镜像
FROM nvidia/opengl:base-ubuntu22.04 as base

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    ISAACSIM_PATH=/isaac-sim \
    CONDA_DIR=/opt/conda \
    PATH=/opt/conda/bin:$PATH \
    # WANDB配置
    WANDB_ENTITY=mrockw520-personal

# 更新包管理器并安装系统依赖 - 合并RUN指令减少层数
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
    # 安装conda依赖
    bzip2 \
    ca-certificates \
    vim \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    /var/cache/apt/archives/* \
    /tmp/* \
    /var/tmp/*

# 下载并安装Miniconda（Python 3.10版本）
RUN wget -q https://repo.anaconda.com/miniconda/Miniconda3-py310_23.11.0-2-Linux-x86_64.sh -O /tmp/miniconda.sh \
    && bash /tmp/miniconda.sh -b -p /opt/conda \
    && rm /tmp/miniconda.sh \
    && conda init bash \
    && conda clean -afy

# 创建工作目录
WORKDIR /workspace

# 创建conda虚拟环境并安装基础依赖
RUN conda create -n env_isaaclab python=3.10 -y \
    && echo "conda activate env_isaaclab" >> ~/.bashrc \
    && /opt/conda/envs/env_isaaclab/bin/pip install --upgrade pip \
    && /opt/conda/envs/env_isaaclab/bin/pip cache purge

# 激活conda环境并设置PATH
ENV PATH=/opt/conda/envs/env_isaaclab/bin:$PATH

# 安装PyTorch (CUDA 12版本) - 使用no-cache-dir减少磁盘占用
RUN pip install --no-cache-dir torch==2.5.1 torchvision==0.20.1 --index-url https://download.pytorch.org/whl/cu121

# 安装Isaac Sim (接受EULA) - 使用最小化安装
RUN pip install 'isaacsim[all,extscache]==4.5.0' --extra-index-url https://pypi.nvidia.com \
    && echo 'y' | isaacsim --help > /dev/null 2>&1 || true \
    && pip cache purge

# 克隆Isaac Lab仓库并切换到指定版本
RUN git clone --depth 1 --branch release/2.1.0 https://github.com/isaac-sim/IsaacLab.git /workspace/IsaacLab

# 安装Isaac Lab依赖
WORKDIR /workspace/IsaacLab
RUN bash -c "source /opt/conda/bin/activate env_isaaclab && ./isaaclab.sh --install"

# 安装wandb和其他可选依赖（按需安装）
RUN pip install --no-cache-dir wandb

# 清理不必要的文件
RUN conda clean -afy \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/* \
    /root/.cache/pip/* \
    /opt/conda/pkgs/*

RUN echo '#!/bin/bash' > /usr/local/bin/start.sh && \
    echo 'source /opt/conda/bin/activate env_isaaclab' >> /usr/local/bin/start.sh && \
    chmod +x /usr/local/bin/start.sh

# 设置默认命令
CMD ["/usr/local/bin/start.sh"]