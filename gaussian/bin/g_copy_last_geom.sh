#!/usr/bin/env bash

if [ $# -ne 2 ]; then
    echo "Usage: $(basename $0) gaussian.log gaussian.gjf"
    exit -1
fi

_gou=$1
_gin=$2
_gtmp="${_gin}.tmp"

_gou_l1=$(grep -n "Input orientation:" $_gou | tail -n1 | cut -d ":" -f 1)
_gou_l1=$((_gou_l1+5))
_gou_l2=$(tail -n +${_gou_l1} $_gou | grep -n -e "----" | head -n1 | cut -d ":" -f 1)
_gou_l2=$((_gou_l1+_gou_l2-2))

_gin_line_no=($(grep -n -E "^[ \t]*$" $_gin | cut -d ":" -f 1))

head -n $((_gin_line_no[1]+1)) $_gin > $_gtmp

paste -d " " <(gawk "NR>${_gin_line_no[1]}+1&&NR<${_gin_line_no[2]}{if (NF==4) print \$1; else print \$1,\$2}" $_gin) <(gawk "NR>=${_gou_l1}&&NR<=${_gou_l2}{print \$4,\$5,\$6}" $_gou) >> $_gtmp

tail -n +${_gin_line_no[2]} $_gin >> $_gtmp

mv -f $_gtmp $_gin
