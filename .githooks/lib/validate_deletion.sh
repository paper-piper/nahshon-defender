#!/usr/bin/env sh

# deletion rule - .txt files may not be deleted once committed.
validate_deletion() {

    if git diff --cached --name-only --diff-filter=D | grep -q '\.txt$'; then
        return 1
    fi
    return 0
}