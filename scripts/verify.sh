#!/bin/bash
# scripts/verify.sh — Test and Benchmark execution

run_tests_internal() {
    "$TEST_BIN" --gtest_output="xml:$ROOT_DIR/test_results.xml"
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo -e "${RED}[!] Tests failed with exit code: $exit_code${NC}"
    else
        echo -e "${GREEN}[PASS] Tests completed successfully.${NC}"
    fi
    return $exit_code
}

run_benchmarks_internal() {
    "$BENCH_BIN" --benchmark_out="$ROOT_DIR/bench_results.json" --benchmark_out_format=json
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo -e "${RED}[!] Benchmarks failed with exit code: $exit_code${NC}"
    else
        echo -e "${GREEN}[PASS] Benchmarks completed successfully.${NC}"
    fi
    return $exit_code
}

execute_verifications() {
    log_step "Step 5: Execution & Artifact"
    ROOT_DIR=$(pwd)

    TEST_BIN=$(find "$OUT_DIR" -name "*tests" -type f -executable | head -n 1)
    BENCH_BIN=$(find "$OUT_DIR" -name "*bench" -type f -executable | head -n 1)

    if [ -n "$TEST_BIN" ]; then
        log_info "Running Tests: $TEST_BIN"
        run_tests_internal
        PIPELINE_TEST_STATUS=$?
    fi

    if [ -n "$BENCH_BIN" ]; then
        log_info "Running Benchmarks: $BENCH_BIN"
        run_benchmarks_internal
        PIPELINE_BENCH_STATUS=$?
    fi

    echo -e "\n${CYAN}--- Artifact Handshake ---${NC}"
    if [ -n "${PIPELINE_TEST_STATUS:-}" ]; then
        [ -f "$ROOT_DIR/test_results.xml" ] && echo -e "  ${GREEN}[PASS]${NC} test_results.xml -> Host" || echo -e "  ${RED}[FAIL]${NC} No test report found."
    fi
    if [ -n "${PIPELINE_BENCH_STATUS:-}" ]; then
        [ -f "$ROOT_DIR/bench_results.json" ] && echo -e "  ${GREEN}[PASS]${NC} bench_results.json -> Host" || echo -e "  ${RED}[FAIL]${NC} No bench report found."
    fi
}