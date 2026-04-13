#!/bin/sh
printf '\033c\033]0;%s\a' Steve_Survivor
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Steve_Survivor.x86_64" "$@"
