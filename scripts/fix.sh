#!/bin/bash
# scripts/fix.sh — Clang-Tidy auto-remediation driver

run_clang_tidy_fix() {
    COMPILE_DB="$OUT_DIR/compile_commands.json"

    if [ ! -f "$COMPILE_DB" ]; then
        echo -e "${RED}[ERROR] No compile_commands.json found at $COMPILE_DB${NC}"
        echo -e "${BLUE}[INFO]${NC} Run './build.sh Dev' first to generate it."
        exit 1
    fi

    TIDY_EXE="clang-tidy"
    log_info "clang-tidy fix — using: $TIDY_EXE"

    SOURCES=$(find src include tests bench -name "*.cpp" -o -name "*.hpp" 2>/dev/null | sort)
    if [ -z "$SOURCES" ]; then
        echo -e "${RED}[ERROR] No source files found under src/ include/ tests/ bench/${NC}"
        exit 1
    fi

    echo -e "${CYAN}--- Files to fix ---${NC}"
    echo "$SOURCES" | while read -r f; do echo "  $f"; done

    echo -e "\n${MAGENTA}Running clang-tidy --fix ...${NC}"
    "$TIDY_EXE" -p "$COMPILE_DB" --fix --fix-errors --format-style=file $SOURCES

    FIX_EXIT=$?
    if [ $FIX_EXIT -eq 0 ]; then
        echo -e "\n${GREEN}${BOLD}✅ clang-tidy --fix completed. Review changes with: git diff${NC}"
    else
        echo -e "\n${RED}[WARN] clang-tidy exited with code $FIX_EXIT — manual fixes needed.${NC}"
    fi
}