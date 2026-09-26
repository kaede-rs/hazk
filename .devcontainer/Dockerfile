# hazkey dev container
#
# Base: the official Swift docker image (Ubuntu 24.04 "noble"), matching
# the swift-6.2-release toolchain used in .github/workflows/build.yml.
# Everything below mirrors that same CI job's apt install list for the
# fcitx5-hazkey / hazkey-settings / protobuf side of the build, plus the
# Vulkan headers/compiler llama.cpp needs to build the Zenzai backend
# (compile-time only — no GPU access required inside the container).
FROM swift:6.2-noble

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        # core build tooling
        build-essential cmake ninja-build git curl wget gnupg2 pkg-config \
        gettext fakeroot file \
        # fcitx5-hazkey
        libfcitx5core-dev libfcitx5config-dev libfcitx5utils-dev \
        # hazkey-settings (Qt6)
        qt6-base-dev qt6-tools-dev qt6-tools-dev-tools \
        libqt6widgets6 libqt6gui6 qt6-l10n-tools \
        libglx-dev libgl1-mesa-dev libxkbcommon-dev \
        # protocol/*.proto
        protobuf-compiler libprotoc-dev \
        # llama.cpp Vulkan backend (Zenzai)
        libvulkan-dev glslc \
    && rm -rf /var/lib/apt/lists/*

# just — runs the top-level Justfile (just configure / build / install)
RUN curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh \
    | bash -s -- --to /usr/local/bin