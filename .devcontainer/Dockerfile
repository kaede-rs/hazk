FROM ubuntu:24.04

ARG SWIFT_VERSION=6.2
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8

# 依存関係のインストール
RUN apt-get update && apt-get install -y --no-install-recommends \
    # 基本ツール
    build-essential ca-certificates curl git gnupg2 wget unzip sudo \
    cmake ninja-build pkg-config gettext fakeroot python3 \
    # Swiftが要求する共有ライブラリ
    binutils libc6-dev libcurl4-openssl-dev libedit2 libgcc-13-dev \
    libpython3.12 libsqlite3-0 libstdc++-13-dev libxml2-dev libz3-dev \
    zlib1g-dev tzdata \
    # protobuf
    protobuf-compiler libprotoc-dev \
    # fcitx5-hazkey
    libfcitx5core-dev libfcitx5config-dev libfcitx5utils-dev \
    # hazkey-settings (Qt6)
    qt6-base-dev qt6-tools-dev qt6-tools-dev-tools \
    libqt6widgets6 libqt6gui6 qt6-l10n-tools \
    libglx-dev libgl1-mesa-dev libxkbcommon-dev \
    # hazkey-server の llama.cpp (Vulkanバックエンド)
    libvulkan-dev glslc \
    && rm -rf /var/lib/apt/lists/*

# Swift toolchain
RUN ARCH="$(dpkg --print-architecture)"; \
    if [ "$ARCH" = "arm64" ]; then \
        PLATFORM_DIR="ubuntu2404-aarch64"; FILE_SUFFIX="ubuntu24.04-aarch64"; \
    else \
        PLATFORM_DIR="ubuntu2404"; FILE_SUFFIX="ubuntu24.04"; \
    fi; \
    URL="https://download.swift.org/swift-${SWIFT_VERSION}-release/${PLATFORM_DIR}/swift-${SWIFT_VERSION}-RELEASE/swift-${SWIFT_VERSION}-RELEASE-${FILE_SUFFIX}.tar.gz"; \
    wget -q "$URL" -O /tmp/swift.tar.gz && \
    mkdir -p /opt/swift && \
    tar xf /tmp/swift.tar.gz --strip-components=1 -C /opt/swift && \
    rm /tmp/swift.tar.gz
ENV PATH="/opt/swift/usr/bin:${PATH}"

ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m -s /bin/bash $USERNAME \
    && echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME
WORKDIR /workspaces/hazk