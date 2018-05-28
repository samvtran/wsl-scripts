#!/usr/bin/env bash
# NOTE: this probably isn't needed (anymore).
# As long as <mount root>/Program Files/Microsoft VS Code/bin/code is accessible, `code` should pick up on paths correctly.
#
# Opens files and folders in a Windows-based Visual Studio Code install by passing Windows paths
# 
set -eu

Path="$1"

{
    AbsolutePath="$(wslpath -w "$(realpath "$Path")" 2>/dev/null)"
} || {
    echo "$Path is inaccessible from Windows"
    exit 1
}

"$(command which code)" "$AbsolutePath"
