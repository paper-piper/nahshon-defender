# filename rules - file must be named with a positive integer and .txt extension, e.g. 1.txt, 2.txt, etc.
validate_filename(){
        file_path="$1"
        filename="${file_path##*/}" # strip anything before the last slash, leaving just the filename
        echo "$filename" | grep -qE '^[1-9][0-9]*\.txt$'
}