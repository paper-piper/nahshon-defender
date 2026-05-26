#!/bin/sh
# validates two rules:
# version folder name - each folder follows the pattern: V_[0-9].[0-9].[0-9] exactly.
# no nesting - checks that each .txt file has a version folder above it, and the version folder is a child of the root.

validate_structure() {
    staged_file="$1"

    # get full path to dir file's directory (everything before the last "/")
    version_dir="${staged_file%%/*}"

    # Isolate everything that follows the first "/". this will be used to check for nesting.
    sub_path="${staged_file#*/}"

    # check if "%%/*" changes nothing - means that the file is at root level.   
    if [ "$version_dir" = "$staged_file" ]; then
        return 1
    fi

    # check for nesting - if there's a slash anywhere on the sub_path.
    case "$sub_path" in
        */*) return 1 ;;
    esac

    # after we are sure the structure is correct, we can be certain that there's a version folder and only its name.
    # therefore we can verify the version folder name with the pattern: V_[0-9].[0-9].[0-9]
    echo "$version_dir" | grep -qE '^V_[0-9]\.[0-9]\.[0-9]$'
}
