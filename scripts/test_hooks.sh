#!/bin/sh

# Always run from the repo root regardless of where the script was invoked from.
cd "$(dirname "$0")/.."

# Ensure the hook is installed and configured before any test runs.
sh scripts/setup.sh

# Save the starting commit so every reset targets it exactly — never HEAD~1,
# which is relative and can overshoot into real commits if anything goes wrong.
ORIGINAL_HEAD=$(git rev-parse HEAD)

# Save any work in progress. Untracked files are intentionally excluded so
# this script (which is untracked) is not stashed while it is running.
git stash -q

PASS=0
FAIL=0
TEST_DIR="V_9.9.9"

# ── Helpers ──────────────────────────────────────────────────────

# Stage files, then call this. The commit should SUCCEED (hook allows it).
assert_allowed() {
    desc="$1"
    if git commit -m "test" -q 2>/dev/null; then
        git reset "$ORIGINAL_HEAD" --hard -q
        printf 'PASS: %s\n' "$desc"
        PASS=$((PASS + 1))
    else
        git restore --staged . -q
        rm -rf "$TEST_DIR"
        printf 'FAIL (should have been allowed): %s\n' "$desc"
        FAIL=$((FAIL + 1))
    fi
}

# Stage files, then call this. The commit should be BLOCKED (hook rejects it).
assert_blocked() {
    desc="$1"
    if git commit -m "test" -q 2>/dev/null; then
        git reset "$ORIGINAL_HEAD" --hard -q
        printf 'FAIL (should have been blocked): %s\n' "$desc"
        FAIL=$((FAIL + 1))
    else
        git restore --staged . -q
        rm -rf "$TEST_DIR"
        printf 'PASS: %s\n' "$desc"
        PASS=$((PASS + 1))
    fi
}

# ── validate_filename ────────────────────────────────────────────

mkdir -p "$TEST_DIR" && touch "$TEST_DIR/1.txt"
git add "$TEST_DIR/1.txt"
assert_allowed "filename: 1.txt (valid)"

mkdir -p "$TEST_DIR" && touch "$TEST_DIR/46.txt"
git add "$TEST_DIR/46.txt"
assert_allowed "filename: 46.txt (valid)"

mkdir -p "$TEST_DIR" && touch "$TEST_DIR/0.txt"
git add "$TEST_DIR/0.txt"
assert_blocked "filename: 0.txt (zero — blocked)"

mkdir -p "$TEST_DIR" && touch "$TEST_DIR/01.txt"
git add "$TEST_DIR/01.txt"
assert_blocked "filename: 01.txt (leading zero — blocked)"

mkdir -p "$TEST_DIR" && touch "$TEST_DIR/1.5.txt"
git add "$TEST_DIR/1.5.txt"
assert_blocked "filename: 1.5.txt (decimal — blocked)"

mkdir -p "$TEST_DIR" && touch "$TEST_DIR/notes.txt"
git add "$TEST_DIR/notes.txt"
assert_blocked "filename: notes.txt (non-numeric — blocked)"

# ── validate_content ─────────────────────────────────────────────

mkdir -p "$TEST_DIR"
printf 'hello world\n' > "$TEST_DIR/1.txt"
git add "$TEST_DIR/1.txt"
assert_allowed "content: regular text (valid)"

mkdir -p "$TEST_DIR"
printf 'Delete this line\n' > "$TEST_DIR/1.txt"
git add "$TEST_DIR/1.txt"
assert_allowed "content: Delete (capital D — valid)"

mkdir -p "$TEST_DIR"
printf 'DELETE everything\n' > "$TEST_DIR/1.txt"
git add "$TEST_DIR/1.txt"
assert_allowed "content: DELETE (all caps — valid)"

mkdir -p "$TEST_DIR"
printf 'delete this line\n' > "$TEST_DIR/1.txt"
git add "$TEST_DIR/1.txt"
assert_blocked "content: delete (lowercase — blocked)"

mkdir -p "$TEST_DIR"
printf 'valid line\ndelete this\n' > "$TEST_DIR/1.txt"
git add "$TEST_DIR/1.txt"
assert_blocked "content: delete on second line (blocked)"

# ── validate_structure ───────────────────────────────────────────

# Valid structure (V_N.N.N/file.txt) is already covered by the tests above.

# invalid: file at repo root with no version folder above it
touch "1.txt"
git add "1.txt"
assert_blocked "structure: 1.txt at repo root (blocked)"
rm -f "1.txt"

# invalid: file nested inside a subdirectory of the version folder
mkdir -p "$TEST_DIR/subdir"
touch "$TEST_DIR/subdir/1.txt"
git add "$TEST_DIR/subdir/1.txt"
assert_blocked "structure: V_9.9.9/subdir/1.txt (nested — blocked)"
rm -rf "$TEST_DIR/subdir"

# invalid: version folder with a multi-digit version component
mkdir -p "V_12.3.4"
touch "V_12.3.4/1.txt"
git add "V_12.3.4/1.txt"
assert_blocked "structure: V_12.3.4 (multi-digit version — blocked)"
rm -rf "V_12.3.4"

# ── validate_append_only ─────────────────────────────────────────

# Setup: commit a file so future commits have existing content to compare against.
mkdir -p "$TEST_DIR"
printf 'line1\nline2\n' > "$TEST_DIR/1.txt"
git add "$TEST_DIR/1.txt"
git commit -m "append_only setup" -q 2>/dev/null
APPEND_SETUP=$(git rev-parse HEAD)

# valid: append new lines at the end
printf 'line1\nline2\nline3\n' > "$TEST_DIR/1.txt"
git add "$TEST_DIR/1.txt"
if git commit -m "test" -q 2>/dev/null; then
    git reset "$APPEND_SETUP" --hard -q   # back to setup commit state
    printf 'PASS: append_only: append line at end (valid)\n'
    PASS=$((PASS + 1))
else
    git restore --staged . -q
    git checkout HEAD -- "$TEST_DIR/1.txt"
    printf 'FAIL (should have been allowed): append_only: append line at end\n'
    FAIL=$((FAIL + 1))
fi

# invalid: modify an existing line
printf 'CHANGED\nline2\n' > "$TEST_DIR/1.txt"
git add "$TEST_DIR/1.txt"
if git commit -m "test" -q 2>/dev/null; then
    git reset "$APPEND_SETUP" --hard -q
    printf 'FAIL (should have been blocked): append_only: modify existing line\n'
    FAIL=$((FAIL + 1))
else
    git restore --staged . -q
    git checkout HEAD -- "$TEST_DIR/1.txt"
    printf 'PASS: append_only: modify existing line (blocked)\n'
    PASS=$((PASS + 1))
fi

# invalid: remove a line
printf 'line1\n' > "$TEST_DIR/1.txt"
git add "$TEST_DIR/1.txt"
if git commit -m "test" -q 2>/dev/null; then
    git reset "$APPEND_SETUP" --hard -q
    printf 'FAIL (should have been blocked): append_only: remove a line\n'
    FAIL=$((FAIL + 1))
else
    git restore --staged . -q
    printf 'PASS: append_only: remove a line (blocked)\n'
    PASS=$((PASS + 1))
fi

# Undo the setup commit.
git reset "$ORIGINAL_HEAD" --hard -q

# ── validate_deletion ────────────────────────────────────────────

# Setup: commit a file so we have a .txt file to attempt to delete.
mkdir -p "$TEST_DIR"
touch "$TEST_DIR/1.txt"
git add "$TEST_DIR/1.txt"
git commit -m "deletion setup" -q 2>/dev/null
DELETION_SETUP=$(git rev-parse HEAD)

# invalid: stage a .txt file for deletion
git rm "$TEST_DIR/1.txt" -q
if git commit -m "test" -q 2>/dev/null; then
    git reset "$DELETION_SETUP" --hard -q
    printf 'FAIL (should have been blocked): deletion: staging .txt for deletion\n'
    FAIL=$((FAIL + 1))
else
    git restore --staged . -q
    printf 'PASS: deletion: staging .txt for deletion (blocked)\n'
    PASS=$((PASS + 1))
fi

# Undo the setup commit.
git reset "$ORIGINAL_HEAD" --hard -q

# ── Summary ──────────────────────────────────────────────────────

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"

git stash pop -q 2>/dev/null || true

[ "$FAIL" -eq 0 ]
