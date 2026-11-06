#!/bin/bash
# scripts/publish.sh — Package publishing step

run_publish() {
    log_step "Step 5: Publishing Release Package"

    if [ -f "conanfile.py" ]; then
        PKG_VERSION=$(grep -E "version\s*=\s*[\"']" conanfile.py | sed -E "s/version\s*=\s*[\"']([^\"']+)[\"']/\1/" | xargs)
        PKG_NAME=$(grep -E "name\s*=\s*[\"']" conanfile.py | sed -E "s/name\s*=\s*[\"']([^\"']+)[\"']/\1/" | xargs)
    fi

    PKG_NAME=${PKG_NAME:-"slot_thread_safe"}
    PKG_VERSION=${PKG_VERSION:-"0.1.1"}
    FULL_PACKAGE_REF="${PKG_NAME}/${PKG_VERSION}@${CONAN_PACKAGE_USER}/${CONAN_PACKAGE_CHANNEL}"

    log_info "Target Reference Identified: ${FULL_PACKAGE_REF}"
    log_info "Enforcing local recipe cache packaging..."

    conan create . \
        --user="${CONAN_PACKAGE_USER}" \
        --channel="${CONAN_PACKAGE_CHANNEL}" \
        -pr:b="./.conan/profiles/$CONAN_PROFILE" \
        -pr:h="./.conan/profiles/$CONAN_PROFILE" \
        -s build_type="Release" --build=missing

    log_info "Uploading fully compiled packages & recipe upstream to ${CONAN_REMOTE_NAME}..."
    conan upload "${FULL_PACKAGE_REF}" --remote="${CONAN_REMOTE_NAME}" --confirm

    echo -e "\n${GREEN}${BOLD}🚀 Package successfully published to upstream server registry!${NC}"
}