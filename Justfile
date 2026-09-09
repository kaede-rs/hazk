build_dir := "build"
backend ?= "vulkan"
mode ?= "Release"

cmake_opts := join(" ", [
    "-DCMAKE_BUILD_TYPE=" + mode,
    "-DCMAKE_INSTALL_PREFIX=/usr",
    "-DGGML_VULKAN=" + ("ON" if backend == "vulkan" else "OFF"),
    "-DGGML_CUDA=" + ("ON" if backend == "cuda" else "OFF"),
    "-G Ninja",
])

configure:
    mkdir -p {{build_dir}}
    cmake -S . -B {{build_dir}} {{cmake_opts}}

build:
    ninja -C {{build_dir}}

install:
    sudo ninja -C {{build_dir}} install

clean:
    rm -rf {{build_dir}}
