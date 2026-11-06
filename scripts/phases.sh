#!/bin/bash
# config/phases.sh — Declarative phase mappings

load_phase_config() {
    PHASE=$(echo "${1:-$DEFAULT_PHASE}" | awk '{print toupper(substr($0,1,1))tolower(substr($0,2))}')

    case "$PHASE" in
        "Debug")
            OUT_DIR=".build-debug"
            CMAKE_MODE="Debug"
            EXTRA_FLAGS="-g -O0"
            CMAKE_FEATURE_FLAGS=""
            ;;
        "Testing")
            OUT_DIR=".build-test"
            CMAKE_MODE="RelWithDebInfo"
            EXTRA_FLAGS="-O3 -g -DSYSTIC_FULL_ASSERT"
            CMAKE_FEATURE_FLAGS="-DBUILD_TESTING=ON -DBUILD_BENCHMARKING=ON"
            ;;
        "Release")
            OUT_DIR=".build"
            CMAKE_MODE="Release"
            EXTRA_FLAGS="-O3 -fomit-frame-pointer -DNDEBUG"
            CMAKE_FEATURE_FLAGS=""
            ;;
        "Dev")
            OUT_DIR=".build-dev"
            CMAKE_MODE="Debug"
            EXTRA_FLAGS="-g -O0 -DSYSTIC_DEV_MODE"
            CMAKE_FEATURE_FLAGS="-DBUILD_TESTING=ON -DBUILD_BENCHMARKING=ON"
            ;;
        "Fix")
            OUT_DIR=".build-dev"
            CMAKE_MODE="Debug"
            EXTRA_FLAGS="-g -O0 -DSYSTIC_DEV_MODE"
            CMAKE_FEATURE_FLAGS=""
            ;;
        "Publish")
            OUT_DIR=".build"
            CMAKE_MODE="Release"
            EXTRA_FLAGS="-O3 -DNDEBUG"
            CMAKE_FEATURE_FLAGS=""
            ;;
        *)
            echo -e "${RED}❌ Unknown phase: $PHASE. Use Debug, Dev, Testing, Fix, Release, or Publish.${NC}"
            exit 1
            ;;
    esac
}