#!/bin/sh

# validate that no newlines were added or removed from the top of the file, only appended
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

    # using word count of type lines to count lines, then stripping spaces with tr.
    committed_line_count=$(git show "HEAD:$staged_file" | wc -l | tr -d ' ')
    # read the first N lines of the staged file, where N is the number of lines in the committed version.
    staged_opening_lines=$(git show ":$staged_file" | head -n "$committed_line_count")
    # Capture the full committed content for the side-by-side comparison.
    committed_content=$(git show "HEAD:$staged_file")

    # The opening lines of the staged file must be byte-for-byte identical to
    # the committed content. Any edit — even a single changed character — fails.
    [ "$staged_opening_lines" = "$committed_content" ]
}