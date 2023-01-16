#!/usr/bin/env bash

print_usage() {
    echo >&2
    echo "usage: $(basename $0) gaussian.gjf" >&2
    echo >&2
}

OPTIND=1
while getopts 'cu' _opt; do
    case $_opt in
        c )
            _comm='!'
            ;;
        u )
            _comm=''
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

sed -i -E $_gin -e "$((_gin_line_no[1]+2)),$((_gin_line_no[2]-1))s/[ !]*([a-zA-Z]+.*)/$_comm\1/"
