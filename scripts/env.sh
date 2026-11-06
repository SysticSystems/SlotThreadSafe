#!/bin/bash
# scripts/env.sh — Environment & Toolchain resolution

# Safe .env loader without unsafe xargs
load_env_safe() {
    local env_file=".env"

    if [ -f "$env_file" ]; then
        set -a
        source <(grep -E '^[A-Za-z_][A-Za-z0-9_]*=' "$env_file")
        set +a
    fi
}

init_defaults() {
    PROJECT_NAME=${PROJECT_NAME}
    DEFAULT_PHASE=${DEFAULT_PHASE:-"Dev"}
    CONAN_PROFILE=${CONAN_PROFILE:-"clang21"}

    # Strict check: ENABLE_CONAN must equal 'ON'
    ENABLE_CONAN=${ENABLE_CONAN:-"OFF"}

    CONAN_REMOTE_NAME=${CONAN_REMOTE_NAME}
    CONAN_REMOTE_URL=${CONAN_REMOTE_URL}
    CONAN_LOGIN_USER=${CONAN_LOGIN_USER}
    CONAN_LOGIN_PASSWORD=${CONAN_LOGIN_PASSWORD}
    CONAN_PACKAGE_USER=${CONAN_PACKAGE_USER}
    CONAN_PACKAGE_CHANNEL=${CONAN_PACKAGE_CHANNEL:-"dev"}
}

resolve_toolchain() {
    if [ -z "$CC" ] || [ -z "$CXX" ]; then
        RAW_CXX=$(command -v clang++-21 || command -v clang++-19 || command -v clang++)
        if [ -n "$RAW_CXX" ]; then
            export CXX=$(realpath "$RAW_CXX")
            export CC=$(realpath "$(echo "$CXX" | sed 's/++//')")
            log_info "Toolchain Resolved: $CXX"
        else
            echo -e "${RED}[ERROR] No Clang compiler found.${NC}"; exit 1
        fi
    fi

    if [ -f "$OUT_DIR/CMakeCache.txt" ]; then
        CACHED_CXX=$(grep "CMAKE_CXX_COMPILER:FILEPATH" "$OUT_DIR/CMakeCache.txt" | cut -d'=' -f2 || true)
        if [[ "$CACHED_CXX" != "$CXX" ]]; then
            log_info "Compiler mismatch in cache. Cleaning [$OUT_DIR]..."
            rm -rf "$OUT_DIR/CMakeCache.txt" "$OUT_DIR/CMakeFiles"
        fi
    fi
}

setup_conan_env() {
    if [ "$ENABLE_CONAN" != "ON" ]; then
        log_info "Conan is DISABLED (ENABLE_CONAN='$ENABLE_CONAN'). Skipping Conan setup."
        return 0
    fi

    CONAN_HOME="${HOME}/.conan2"
    mkdir -p "$CONAN_HOME"

    if [ ! -f "$CONAN_HOME/global.conf" ]; then
        echo "tools.cmake.cmaketoolchain:generator=Ninja" > "$CONAN_HOME/global.conf"
        echo "tools.cmake:cmake_program=$(command -v cmake)" >> "$CONAN_HOME/global.conf"
    fi

    if [ -n "$CONAN_REMOTE_NAME" ] && [ -n "$CONAN_REMOTE_URL" ]; then
        log_info "Configuring remote registry mapping ($CONAN_REMOTE_NAME)..."
        conan remote add "${CONAN_REMOTE_NAME}" "${CONAN_REMOTE_URL}" --force >/dev/null 2>&1 || true

        if [ -n "$CONAN_LOGIN_USER" ] && [ -n "$CONAN_LOGIN_PASSWORD" ]; then
            log_info "Authenticating to remote storage context..."
            conan remote login "${CONAN_REMOTE_NAME}" "${CONAN_LOGIN_USER}" --password "${CONAN_LOGIN_PASSWORD}"
        fi
    fi
}