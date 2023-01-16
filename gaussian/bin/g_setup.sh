#!/usr/bin/env bash

print_usage() {
    echo >&2
    echo "usage: $(basename $0) [-c] [-f] [-s] gaussian.gjf" >&2
    echo >&2
}

OPTIND=1
while getopts 'cfs' _opt; do
    case $_opt in
        c )
            _cont=1
            ;;
        f )
            _freq=1
            ;;
        s )
            _solv=1
            ;;
        \?)
            print_usage
            exit -1
            ;;
    esac
done
shift $(($OPTIND - 1))

if [ $# -ne 1 ]; then
    print_usage
    exit -1;
fi

_gin=$1

_gin_line_no=($(grep -n -E "^[ \t]*$" $_gin | cut -d ":" -f 1))

if [ "$_cont" ]; then
    $(dirname "${BASH_SOURCE[0]}")/g_coord.sh -c $_gin
    sed -i -E $_gin \
        -e "1,${_gin_line_no[0]}s/[ !]*(#.*opt)$/!\1/i" \
        -e "1,${_gin_line_no[0]}s/[ !]*(# *opt=readfc.*)/\1/i"
else
    $(dirname "${BASH_SOURCE[0]}")/g_coord.sh -u $_gin
    _comm_geom='!'
    sed -i -E $_gin \
        -e "1,${_gin_line_no[0]}s/[ !]*(# *opt)$/\1/i" \
        -e "1,${_gin_line_no[0]}s/[ !]*(#.*opt=readfc.*)/!\1/i"
fi

if [ ! "$_freq" ]; then
    _comm_freq='!'
fi

if [ ! "$_solv" ]; then
    _comm_solv='!'
fi

sed -i -E $_gin \
    -e "1,${_gin_line_no[0]}s/[ !]*(# *geom.*)/$_comm_geom\1/i" \
    -e "1,${_gin_line_no[0]}s/[ !]*(# *freq.*)/$_comm_freq\1/i" \
    -e "1,${_gin_line_no[0]}s/[ !]*(#.*scrf.*)/$_comm_solv\1/i"
