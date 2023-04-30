#!/usr/bin/env bash

set -e

mmark_version="2.2.10"
url="https://github.com/mmarkdown/mmark/releases/download/v${mmark_version}/mmark_${mmark_version}_linux_amd64.tgz"
tmp=$(mktemp "mmark_${mmark_version}_linux_amd64XXXXX.tgz")

dir="/usr/local/bin/mmark"

curl -sSLf "$url" -o "$tmp";
tar xzfO "$tmp" mmark >"$dir"; chmod 755 "$dir";

rm -f "$tmp"
