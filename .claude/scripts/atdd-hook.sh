#!/bin/bash
# ATDD Stop Hook
# 단계 전이 자동화 및 상태 관리

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
STATE_FILE="$PROJECT_ROOT/.atdd-state.json"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 상태 파일 생성 또는 업데이트
update_state() {
    local phase="$1"
    local feature_file="$2"
    local status="$3"
    local additional_files="${4:-[]}"

    if [[ -f "$STATE_FILE" ]]; then
        # 기존 상태 파일 업데이트
        existing_files=$(jq -r '.generated_files // []' "$STATE_FILE")
        merged_files=$(echo "$existing_files $additional_files" | jq -s 'add | unique')

        jq --arg phase "$phase" \
           --arg feature "$feature_file" \
           --arg status "$status" \
           --argjson files "$merged_files" \
           '{
               current_phase: $phase,
               feature_file: $feature,
               status: $status,
               generated_files: $files,
               updated_at: now | todate
           }' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
    else
        # 새 상태 파일 생성
        jq -n \
           --arg phase "$phase" \
           --arg feature "$feature_file" \
           --arg status "$status" \
           --argjson files "$additional_files" \
           '{
               current_phase: $phase,
               feature_file: $feature,
               status: $status,
               generated_files: $files,
               created_at: now | todate,
               updated_at: now | todate
           }' > "$STATE_FILE"
    fi

    log_success "State updated: phase=$phase, status=$status"
}

# 현재 단계 출력
print_current_state() {
    if [[ -f "$STATE_FILE" ]]; then
        log_info "Current ATDD State:"
        jq -r '"
        Phase: \(.current_phase)
        Feature: \(.feature_file)
        Status: \(.status)
        Generated Files: \([.generated_files[] // empty])
        Updated: \(.updated_at)
        "' "$STATE_FILE" | sed 's/^[ \t]*//'
    else
        log_warning "No state file found. This appears to be a fresh start."
    fi
}

# 다음 단계 안내
print_next_steps() {
    local current_phase="$1"

    echo ""
    log_info "==================================="
    log_info "ATDD Workflow Transition"
    log_info "==================================="
    echo ""

    case "$current_phase" in
        test)
            echo "✅ Test Phase Complete!"
            echo ""
            echo "Generated Glue Code files. Next steps:"
            echo "  1. Review the generated step definitions"
            echo "  2. Run: /atdd-generate (continues to Code Phase)"
            echo "  3. Or: /atdd-edit (modify the generated code)"
            echo ""
            ;;
        code)
            echo "✅ Code Phase Complete!"
            echo ""
            echo "Generated Production Code files. Next steps:"
            echo "  1. Review the generated production code"
            echo "  2. Run: ./gradlew test (execute tests)"
            echo "  3. Or: /atdd-edit (modify the generated code)"
            echo ""
            ;;
        refactor)
            echo "✅ Refactor Phase Complete!"
            echo ""
            echo "All tests passing! Implementation complete."
            echo "Next steps:"
            echo "  1. Review test coverage"
            echo "  2. Consider refactoring improvements"
            echo "  3. Run: /atdd-init (start new feature)"
            echo ""
            ;;
        *)
            log_warning "Unknown phase: $current_phase"
            ;;
    esac
}

# 메인 실행
main() {
    local phase="${1:-}"
    local feature_file="${2:-}"
    local status="${3:-completed}"
    local generated_files="${4:-}"

    if [[ -z "$phase" ]]; then
        log_error "Usage: $0 <phase> [feature_file] [status] [generated_files_json]"
        exit 1
    fi

    log_info "ATDD Hook invoked for phase: $phase"

    # 상태 업데이트
    if [[ -n "$feature_file" ]]; then
        update_state "$phase" "$feature_file" "$status" "$generated_files"
    fi

    # 현재 상태 출력
    print_current_state

    # 다음 단계 안내
    print_next_steps "$phase"

    log_success "Hook execution completed"
}

# 인자 없이 실행되면 현재 상태만 출력
if [[ $# -eq 0 ]]; then
    print_current_state
else
    main "$@"
fi
