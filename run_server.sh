#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# Ruby/Sass need UTF-8 when compiling styles containing non-ASCII characters.
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

exec bundle exec jekyll liveserve --host 127.0.0.1 "$@"
