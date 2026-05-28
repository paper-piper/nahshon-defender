#!/usr/bin/env sh

# validate that they were no lines modified or deleted comprated to priviews commit.
validate_append_only() {
    staged_file="$1"

    # check for first commit — there's nothing to compare against, so the check passes
    if ! git rev-parse HEAD >/dev/null 2>&1; then
        return 0
    fi

    # check for new file - no context to compare against, so the check passes
    if ! git show "HEAD:$staged_file" >/dev/null 2>&1; then
        return 0
    fi

    committed_line_count=$(git show "HEAD:$staged_file" | awk 'END {print NR}')

    # Write both sides to temp files so $() never gets a chance to eat trailing newlines.
    tmp_committed=$(mktemp)
    tmp_staged=$(mktemp)
    git show "HEAD:$staged_file"                                  > "$tmp_committed"
    git show ":$staged_file" | head -n "$committed_line_count"    > "$tmp_staged"

    # cmp -s compares byte-for-byte silently — exit 0 means identical, 1 means different.
    cmp -s "$tmp_committed" "$tmp_staged"
    result=$?

    rm -f "$tmp_committed" "$tmp_staged"
    return "$result"
}