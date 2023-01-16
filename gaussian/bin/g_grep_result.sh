#!/usr/bin/env bash

print_usage() {
    echo >&2
    echo "usage: $(basename $0) [-g] gaussian.log" >&2
    echo >&2
}

OPTIND=1
while getopts 'g' _opt; do
    case $_opt in
        g )
            _deltaG=1
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

_gou=$1

grep "SCF Done:  E" $_gou | tail -n1 | gawk '{print $5}'

[ "$_deltaG" ] && grep -A1 "Sum of electronic and thermal Enthalpies" $_gou | gawk '{print $NF}'
