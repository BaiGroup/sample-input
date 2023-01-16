#!/usr/bin/env bash

print_usage() {
    echo >&2
    echo "usage: $(basename $0) [-f functional] [-b basis] gaussian.gjf" >&2
    echo >&2
}

OPTIND=1
while getopts 'b:f:' _opt; do
    case $_opt in
        b )
            _basis=$OPTARG
            ;;
        f )
            _func=$OPTARG
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

if [ "$_basis" ]; then
    _basis_line_no=($(grep -n -E "^\*{4,}$" $_gin | cut -d ":" -f 1))
    for _line_no in "${_basis_line_no[@]}"; do
        sed -i $_gin \
            -e "$((_line_no-1))s/.*/$_basis/"
    done
fi

if [ "$_func" ]; then
    sed -i -E $_gin \
        -e "1,${_gin_line_no[0]}s; *(#.* +)[a-zA-Z0-9]+/(.*)/(.*);\1$_func/\2/\3;"
fi
