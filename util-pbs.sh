if [ "$HOSTS" ]; then
  ROOT=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
  NODE=($HOSTS)
  echo ${NODE[@]}
else
  ROOT=$PBS_O_WORKDIR
  WALLTIME=$PBS_WALLTIME
  NODE=($(uniq $PBS_NODEFILE))
  #echo ${NODE[@]} > tmp-$PBS_JOBID
  HOSTS=${NODE[@]}
  nprocpernode=$PBS_NUM_PPN
fi
cd "$ROOT"
#######################################################################
FILELOG=log
if [ -z "$nprocperjob" ]; then
    nnodeperjob=$(echo $HOSTS|wc -w) #$PBS_NUM_NODES or $SLURM_NNODES
    nprocperjob=$((nnodeperjob*nprocpernode))
    [ -f ./util.sh ] && source util.sh
fi
HOSTS=${HOSTS// /,}
#######################################################################
echo "Hostname: $(hostname);  ROOT: $ROOT"
echo "Executable: $PROG"
echo "MPIRUN: $MPIRUN"
echo "Hosts: $HOSTS"
echo "nprocpernode: $nprocpernode; nnodeperjob: $nnodeperjob"
echo
