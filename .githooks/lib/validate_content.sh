#!/bin/sh
# content rule - no line in a .txt file may begin with "delete"

validate_content() {
    staged_file="$1"

    # git show ":$staged_file" to get all of the file content
    # grep -q '^delete' to check if any line starts with "delete"
    # we use return values to indicate pass/fail and not reverse the logic for shorter code
    if git show ":$staged_file" | grep -q '^delete'; then
        return 1
    fi

    return 0
}