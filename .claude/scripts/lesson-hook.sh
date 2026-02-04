#!/bin/bash
# Lesson Study Hook
# State management for lesson study workflow with session resume capability

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
STATE_FILE="$PROJECT_ROOT/.study-state.json"

# Color definitions
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

# Create or update state file
update_state() {
    local phase="$1"
    local project_url="$2"
    local questions_asked="${3:-[]}"
    local document_status="${4:-pending}"

    if [[ -f "$STATE_FILE" ]]; then
        # Update existing state file
        existing_questions=$(jq -r '.questions_asked // []' "$STATE_FILE")
        merged_questions=$(echo "$existing_questions $questions_asked" | jq -s 'add | unique')

        jq --arg phase "$phase" \
           --arg url "$project_url" \
           --arg doc_status "$document_status" \
           --argjson questions "$merged_questions" \
           '{
               project_url: $url,
               current_phase: $phase,
               questions_asked: $questions,
               document_status: $doc_status,
               updated_at: now | todate
           }' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
    else
        # Create new state file
        jq -n \
           --arg phase "$phase" \
           --arg url "$project_url" \
           --arg doc_status "$document_status" \
           --argjson questions "$questions_asked" \
           '{
               project_url: $url,
               current_phase: $phase,
               questions_asked: $questions,
               document_status: $doc_status,
               created_at: now | todate,
               updated_at: now | todate
           }' > "$STATE_FILE"
    fi

    log_success "State updated: phase=$phase, document_status=$document_status"
}

# Print current state
print_current_state() {
    if [[ -f "$STATE_FILE" ]]; then
        log_info "Current Lesson Study State:"
        jq -r '"
        Project URL: \(.project_url // "not set")
        Phase: \(.current_phase)
        Questions Asked: \([.questions_asked[] // empty] | join(", ") // "none")
        Document Status: \(.document_status)
        Updated: \(.updated_at)
        "' "$STATE_FILE" | sed 's/^[ \t]*//'
    else
        log_warning "No study state file found. This appears to be a fresh start."
    fi
}

# Print next steps based on current phase
print_next_steps() {
    local current_phase="$1"

    echo ""
    log_info "==================================="
    log_info "Lesson Study Workflow"
    log_info "==================================="
    echo ""

    case "$current_phase" in
        init)
            echo "📚 Initialization Phase Complete!"
            echo ""
            echo "Study session initialized. Next steps:"
            echo "  1. Project URL has been set"
            echo "  2. Use /lesson-analyze to begin project analysis"
            echo ""
            ;;
        analyzing)
            echo "🔍 Analysis Phase Complete!"
            echo ""
            echo "Project analysis finished. Next steps:"
            echo "  1. Review the questions asked during analysis"
            echo "  2. Use /lesson-generate to create documentation"
            echo ""
            ;;
        generating)
            echo "✍️  Documentation Generation Complete!"
            echo ""
            echo "Lesson document has been generated. Next steps:"
            echo "  1. Review the generated documentation"
            echo "  2. Use /lesson-complete to finalize the study"
            echo ""
            ;;
        complete)
            echo "🎉 Study Session Complete!"
            echo ""
            echo "All phases finished successfully!"
            echo "  1. Documentation is ready"
            echo "  2. State has been saved for future reference"
            echo "  3. Use /lesson-init to start a new study"
            echo ""
            ;;
        *)
            log_warning "Unknown phase: $current_phase"
            ;;
    esac
}

# Resume session information
print_resume_info() {
    if [[ -f "$STATE_FILE" ]]; then
        local phase=$(jq -r '.current_phase' "$STATE_FILE")
        local url=$(jq -r '.project_url' "$STATE_FILE")
        local doc_status=$(jq -r '.document_status' "$STATE_FILE")

        echo ""
        log_info "==================================="
        log_info "Session Resume Information"
        log_info "==================================="
        echo ""
        log_info "You can resume your study session from: $phase"
        log_info "Project: $url"
        log_info "Document status: $doc_status"
        echo ""
    fi
}

# Main execution
main() {
    local phase="${1:-}"
    local project_url="${2:-}"
    local questions_asked="${3:-[]}"
    local document_status="${4:-pending}"

    if [[ -z "$phase" ]]; then
        log_error "Usage: $0 <phase> [project_url] [questions_asked_json] [document_status]"
        log_error "Phases: init | analyzing | generating | complete"
        exit 1
    fi

    # Validate phase
    case "$phase" in
        init|analyzing|generating|complete)
            ;;
        *)
            log_error "Invalid phase: $phase"
            log_error "Valid phases: init, analyzing, generating, complete"
            exit 1
            ;;
    esac

    log_info "Lesson Hook invoked for phase: $phase"

    # Update state if project_url is provided
    if [[ -n "$project_url" ]]; then
        update_state "$phase" "$project_url" "$questions_asked" "$document_status"
    fi

    # Print current state
    print_current_state

    # Print next steps
    print_next_steps "$phase"

    # Print resume info
    print_resume_info

    log_success "Hook execution completed"
}

# If no arguments, just print current state
if [[ $# -eq 0 ]]; then
    print_current_state
    print_resume_info
else
    main "$@"
fi
