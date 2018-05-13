#!/bin/bash

##
# MIT License
#
# Copyright (c) 2017 August Valera
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
#
# @file open-window.sh
# @brief Opens files on Windows Subsystem for Linux with default Windows applications
# @author August Valera
#
# Original source: https://gitlab.com/4U6U57/wsl-open
#
# @version 2
# @date 2018-12-5
#
# Updates:
# - Using wslpath to reconcile Windows paths instead of constructing them by hand
# - Support for changing the root in /etc/wsl.conf since wslpath doesn't care
# - Removed temp file copying for files that aren't accessible in Windows
# - Removed browser configuration. Use xdg-open directly and set wsl-open as the browser yourself.
# - Removed bash file checks. Zsh is neat too! :)

# Global
# shellcheck disable=SC1117
# This is for the explicit manpage

# Variables
Exe=$(basename "$0" .sh)
WslOpenExe=${WslOpenExe:-"powershell.exe Start"}
EnableWslCheck=${EnableWslCheck:-true}
DryRun=${DryRun:-false}
DefaultsFile=${DefaultsFile:-~/.mailcap}

# Error functions
Error() {
  echo "$Exe: ERROR: $*" >&2
  exit 1
}
Warning() {
  echo "$Exe: WARNING: $*" >&2
}

# Usage message, ran on help (-h)
Usage="
.\" IMPORT wsl-open.1
.TH \"WSL\-OPEN\" \"1\" \"December 2017\" \"wsl-open 1.1.0\" \"wsl-open manual\"
.SH \"NAME\"
\fBwsl-open\fR
.SH SYNOPSIS
.P
\fBwsl\-open [OPTIONS] { FILE | DIRECTORY | URL }\fP
.SH DESCRIPTION
.P
wsl\-open is a shell script that uses Bash for Windows' \fBpowershell\.exe Start\fP
command to open files with Windows applications\.
.SH OPTIONS
.P
\fB\-h\fP
displays this help page
.P
\fB\-a\fP
associates this script with xdg\-open for files like this
.P
\fB\-d\fP
disassociates this script with xdg\-open for files like this
.P
\fB\-w\fP
associates this script with xdg\-open for links (\fBhttp://\fP)
.P
\fB\-x\fP
dry run, does not open file, just echos command used to do it\.
Useful for testing\.
.SH EXAMPLES
.P
\fBwsl\-open manual\.docx\fP
.P
\fBwsl\-open /mnt/c/Users/Test\\ User/Downloads/profile\.png\fP
.P
\fBwsl\-open https://gitlab\.com/4U6U57/wsl\-open\fP
.P
\fBwsl\-open \-a README\.txt\fP
.SH AUTHORS
.P
\fBAugust Valera\fR @4U6U57 on GitLab/GitHub
.SH SEE ALSO
.P
xdg\-open(1), Project Page \fIhttps://gitlab\.com/4U6U57/wsl\-open\fR

.\" END IMPORT wsl-open.1
"

# Printer for dry run function
DryRunner() {
  echo "$Exe: RUN: $*"
}

# Check that we're on Windows Subsystem for Linux
# shellcheck disable=SC2154
if $EnableWslCheck; then
  [[ $(uname -r) != *Microsoft ]] && Error "Could not detect WSL (Windows Subsystem for Linux)"
fi

# Check command line arguments
while getopts "ha:d:wx" Opt; do
  case $Opt in
    (h)
      man <(echo "$Usage")
      ;;
    (a)
      File=$OPTARG
      [[ ! -e $File ]] && Error "File does not exist: $File"
      Type=$(xdg-mime query filetype "$File")
      TypeSafe="${Type//\//\\/}"
      echo "Associating type $Type with $Exe"
      if ! $DryRun; then
        sed -i "/$TypeSafe/d" "$DefaultsFile"
        echo "$Type; $Exe '%s'" >>"$DefaultsFile"
      else
        DryRunner "sed -i \"/$TypeSafe/d\" \"$DefaultsFile\""
        DryRunner "echo \"$Type; $Exe '%s'\" >>\"$DefaultsFile\""
      fi
      ;;
    (d)
      File=$OPTARG
      [[ ! -e $File ]] && Error "File does not exist: $File"
      Type=$(xdg-mime query filetype "$File")
      TypeSafe="${Type//\//\\/}"
      echo "Disassociating type $Type with $Exe"
      if ! $DryRun; then
        sed -i "/$TypeSafe.*open-window/d" "$DefaultsFile"
      else
        DryRunner "sed -i \"/$TypeSafe.*open-window/d\" \"$DefaultsFile\""
      fi
      ;;
    (x)
      DryRun=true
      ;;
    (?)
      Error "Invalid option: -$OPTARG"
      ;;
  esac
done
shift $(( OPTIND - 1 ))

# Open file
File=$1
if [[ ! -z $File ]]; then
  if [[ $File == *://* ]]; then
    # If "file" input is a link, just pass it directly
    FileWin=$File

  elif [[ -e $File ]]; then
    # File or directory
    FilePath="$(readlink -f "$File")"
    {
      FileWin=$(wslpath -w "$FilePath")
    } || {
      Error "'$File' is not accessible from Windows"
    }

  else
    Error "File/directory does not exist: $File"
  fi

  # Open the file with Windows
  if ! $DryRun; then
    $WslOpenExe "\"$FileWin\""
  else
    DryRunner "$WslOpenExe \"$FileWin\""
  fi
fi
