#!/usr/bin/env bash
# Black-box regression tests for bsearch.
#
# Usage:
#   bash tests/test_bsearch.sh [path/to/bsearch]
#
# The tests run bsearch with a temporary HOME, so they do not touch the
# caller's real ~/.local/state/bsearch.db. A fake pdfinfo provides repeatable
# PDF metadata without requiring real PDF fixtures or Poppler.

# NOTE: This test is generated using AI (ChatGPT GPT-6).

set -uo pipefail

SCRIPT=${1:-"$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/bsearch"}

if [[ ! -x "$SCRIPT" ]]; then
    printf 'ERROR: bsearch not found or not executable: %s\n' "$SCRIPT" >&2
    exit 2
fi

TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/bsearch-tests.XXXXXX") || exit 2
trap 'rm -rf -- "$TEST_ROOT"' EXIT

PASS=0
FAIL=0
CURRENT_HOME=""
CURRENT_ROOT=""

new_sandbox() {
    CURRENT_HOME="$TEST_ROOT/home-$((PASS + FAIL + 1))"
    CURRENT_ROOT="$TEST_ROOT/data-$((PASS + FAIL + 1))"
    mkdir -p -- "$CURRENT_HOME" "$CURRENT_ROOT" "$TEST_ROOT/bin"
    export HOME="$CURRENT_HOME"
    export PATH="$TEST_ROOT/bin:$PATH"

    # Use predictable metadata. The script prefers pdfinfo if it is present.
    cat >"$TEST_ROOT/bin/pdfinfo" <<'MOCK_PDFINFO'
#!/usr/bin/env bash
case "${1##*/}" in
    alpha-report.pdf)
        cat <<'EOF'
Title: Alpha Report
Creator: LibreOffice
Producer: Test PDF Engine
PDF version: 1.7
Tagged: yes
Encrypted: no
EOF
        ;;
    beta-notes.pdf)
        cat <<'EOF'
Title: Beta Notes
Creator: LaTeX
Producer: Test PDF Engine
PDF version: 1.4
Tagged: no
Encrypted: no
EOF
        ;;
    *)
        cat <<'EOF'
Title: Untitled
Creator: Unknown
Producer: Test PDF Engine
PDF version: 1.5
Tagged: no
Encrypted: no
EOF
        ;;
esac
MOCK_PDFINFO
    chmod +x "$TEST_ROOT/bin/pdfinfo"
}

make_fixtures() {
    mkdir -p -- "$CURRENT_ROOT/reports" "$CURRENT_ROOT/notes" "$CURRENT_ROOT/nested"
    printf 'fake PDF fixture\n' >"$CURRENT_ROOT/reports/alpha-report.pdf"
    printf 'fake PDF fixture\n' >"$CURRENT_ROOT/notes/beta-notes.pdf"
    printf 'plain text fixture\n' >"$CURRENT_ROOT/nested/alpha-readme.txt"
    printf 'plain text fixture\n' >"$CURRENT_ROOT/ordinary.txt"
}

run_bsearch() {
    "$SCRIPT" "$@"
}

assert_contains() {
    local haystack=$1
    local needle=$2
    local description=$3
    if [[ "$haystack" == *"$needle"* ]]; then
        printf 'PASS: %s\n' "$description"
        ((PASS += 1))
    else
        printf 'FAIL: %s\n  expected output to contain: %s\n  actual output:\n%s\n' \
            "$description" "$needle" "$haystack" >&2
        ((FAIL += 1))
    fi
}

assert_not_contains() {
    local haystack=$1
    local needle=$2
    local description=$3
    if [[ "$haystack" != *"$needle"* ]]; then
        printf 'PASS: %s\n' "$description"
        ((PASS += 1))
    else
        printf 'FAIL: %s\n  output unexpectedly contained: %s\n  actual output:\n%s\n' \
            "$description" "$needle" "$haystack" >&2
        ((FAIL += 1))
    fi
}

assert_status_zero() {
    local status=$1 description=$2 output=${3:-}
    if (( status == 0 )); then
        printf 'PASS: %s\n' "$description"
        ((PASS += 1))
    else
        printf 'FAIL: %s (exit=%d)\n%s\n' "$description" "$status" "$output" >&2
        ((FAIL += 1))
    fi
}

assert_status_nonzero() {
    local status=$1 description=$2 output=${3:-}
    if (( status != 0 )); then
        printf 'PASS: %s\n' "$description"
        ((PASS += 1))
    else
        printf 'FAIL: %s (expected nonzero exit)\n%s\n' "$description" "$output" >&2
        ((FAIL += 1))
    fi
}

# 1. CLI usage: no arguments should print usage and fail cleanly.
new_sandbox
out=$(run_bsearch 2>&1)
status=$?
assert_status_nonzero "$status" "no arguments returns nonzero" "$out"
assert_contains "$out" "Usage:" "no arguments displays usage"

# 2. Index only PDFs; a text file should not appear in the file-list count
#    or become searchable as a filename token.
new_sandbox
make_fixtures
out=$(run_bsearch -t pdf -r "$CURRENT_ROOT" 2>&1)
status=$?
assert_status_zero "$status" "PDF indexing exits successfully" "$out"
assert_contains "$out" "Created 2 hash index entries." "extension filter indexes two PDFs"

out=$(run_bsearch -s "alpha-readme" 2>&1)
assert_not_contains "$out" "$CURRENT_ROOT/nested/alpha-readme.txt" \
    "PDF-only index excludes non-PDF files"

# 3. Index all files, including non-PDF files.
new_sandbox
make_fixtures
out=$(run_bsearch -t all -r "$CURRENT_ROOT" 2>&1)
status=$?
assert_status_zero "$status" "index-all exits successfully" "$out"
assert_contains "$out" "Created 4 hash index entries." "index-all indexes all four files"

# 4. Search filename/path tokens and case-insensitive queries.
out=$(run_bsearch -s "alpha-report" 2>&1)
assert_contains "$out" "$CURRENT_ROOT/reports/alpha-report.pdf" \
    "exact filename-token search returns the matching path"

out=$(run_bsearch -s "ALPHA-REPORT" 2>&1)
assert_contains "$out" "$CURRENT_ROOT/reports/alpha-report.pdf" \
    "filename search is case-insensitive"

# 5. Fuzzy substring search should find a token containing the query.
out=$(run_bsearch -s "alpha" 2>&1)
assert_contains "$out" "$CURRENT_ROOT/reports/alpha-report.pdf" \
    "fuzzy filename search finds a substring"

# 6. PDF metadata query: the indexed Title should be searchable.
out=$(run_bsearch -s "title:alpha" 2>&1)
assert_contains "$out" "$CURRENT_ROOT/reports/alpha-report.pdf" \
    "metadata search finds a title substring"

out=$(run_bsearch -s "creator:libreoffice" 2>&1)
assert_contains "$out" "$CURRENT_ROOT/reports/alpha-report.pdf" \
    "metadata search finds Creator"

# 7. An absent search term should not return any fixture path.
out=$(run_bsearch -s "definitely-not-present-xyz" 2>&1)
assert_not_contains "$out" "$CURRENT_ROOT/" "unmatched query returns no fixture paths"

# 8. Empty/nonexistent root should fail with a clear diagnostic.
new_sandbox
mkdir -p -- "$CURRENT_ROOT"
out=$(run_bsearch -t all -r "$CURRENT_ROOT" 2>&1)
status=$?
assert_status_nonzero "$status" "empty root returns nonzero" "$out"
assert_contains "$out" "No files were found" "empty root reports that no files were found"

new_sandbox
out=$(run_bsearch -t all -r "$CURRENT_ROOT/does-not-exist" 2>&1)
status=$?
assert_status_nonzero "$status" "nonexistent root returns nonzero" "$out"

printf '\nResults: %d passed, %d failed\n' "$PASS" "$FAIL"
if (( FAIL > 0 )); then
    exit 1
fi
exit 0
