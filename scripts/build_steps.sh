#!/bin/bash
# scripts/build_steps.sh — Core compilation drivers

run_conan_install() {
    mkdir -p "$OUT_DIR"
    if [ ! -f "$OUT_DIR/conan_toolchain.cmake" ]; then
        log_info "Step 2: Conan install (Profile: $CONAN_PROFILE)"
        conan install . -of "$OUT_DIR" --build=missing \
             -pr:b="./.conan/profiles/$CONAN_PROFILE" \
             -pr:h="./.conan/profiles/$CONAN_PROFILE" \
             -s build_type="$CMAKE_MODE" \
             -g CMakeDeps -g CMakeToolchain
    else
        log_info "Step 2: Skipping Conan (Cache hit)"
    fi
}

run_cmake_build() {
    TOOLCHAIN_FILE=$(find "$OUT_DIR" -name "conan_toolchain.cmake" | head -n 1)
    [ -f "$OUT_DIR/conanbuild.sh" ] && source "$OUT_DIR/conanbuild.sh"

    log_info "Step 3: CMake Configure (Ninja)"
    cmake -G "Ninja" -S . -B "$OUT_DIR" \
         -DCMAKE_TOOLCHAIN_FILE="$(realpath "$TOOLCHAIN_FILE")" \
         -DCMAKE_BUILD_TYPE="$CMAKE_MODE" \
         -DCMAKE_CXX_COMPILER="$CXX" \
         -DCMAKE_C_COMPILER="$CC" \
         -DCMAKE_CXX_FLAGS="$EXTRA_FLAGS" \
         -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
         ${CMAKE_FEATURE_FLAGS:-}

    log_info "Step 4: Compiling"
    cmake --build "$OUT_DIR" -j$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN)
}