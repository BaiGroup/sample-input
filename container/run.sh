#!/bin/bash

set -e

if [ -e '/opt/intel/oneapi/setvars.sh' ]; then
    _save_args=("${@}")
    source /opt/intel/oneapi/setvars.sh
    set -- "${_save_args[@]}"
elif [ -e '/opt/nvidia/hpc_sdk' ]; then
    export NVARCH=`uname -s`_`uname -m`
    export NVCOMPILERS=/opt/nvidia/hpc_sdk
    export MANPATH="$NVCOMPILERS/$NVARCH/20.11/compilers/man${MANPATH:+:$MANPATH}"
    export PATH="$NVCOMPILERS/$NVARCH/20.11/compilers/bin${PATH:+:$PATH}"
fi

ulimit -s unlimited

exec "$@"
