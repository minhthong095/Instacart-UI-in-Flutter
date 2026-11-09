#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

for svg in asset/*.svg; do
  dart run vector_graphics_compiler -i "$svg" -o "$svg.vec"
done
