#!/usr/bin/env bash

sed -i -E -e '/^REMARK/d' -e '/^CRYST1/d' -e '/^ORIGX/d' -e '/^SCALE/d' -e '/^CONECT/d' "$@"

for a in "$@"; do
  echo 'x' | ex -s -c '1,$-2!sort -k 3,3' "$a"
done
