#!/bin/sh

validate_unique() {
    staged_file="$1"

    # sort the file and check for duplicates
    if git show ":$staged_file" | sort | uniq -d | grep -q .; then
        return 1
    fi
}