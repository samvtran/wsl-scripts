#!/usr/bin/env bash
#
# Opens files and folders in a Windows-based Visual Studio Code install by passing Windows paths

set -eu

Path="$1"

{
    AbsolutePath="$(wslpath -w "$(realpath "$Path")" 2>/dev/null)"
} || {
    echo "$Path is inaccessible from Windows"
    exit 1
}

"$(command which code)" "$AbsolutePath"