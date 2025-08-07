#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <SOURCE_ROOT> <DEST_ROOT>"
  exit 1
fi

SOURCE_ROOT=$1
DEST_ROOT=$2

find "$SOURCE_ROOT" -type f -name '*all-country-est_*.RDS' -print0 \
| while IFS= read -r -d '' file; do
    # strip SOURCE_ROOT/ from path to get relative subdir (including solver & HS/year)
    rel_path="${file#$SOURCE_ROOT/}"
    dest="$DEST_ROOT/$rel_path"

    mkdir -p "$(dirname "$dest")"
    cp "$file" "$dest"
done
