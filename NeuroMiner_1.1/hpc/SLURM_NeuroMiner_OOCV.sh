#!/bin/bash 

echo
echo '******************************************'
echo '***          NeuroMiner 1.1            ***'
echo '***       SGE joblist manager:         ***'
echo '***  Apply models to independent data  ***'
echo '***      (c) 2022 N. Koutsouleris      ***'
echo '******************************************'
echo '            VERSION 1.1 Beorn	            '
echo '******************************************'
echo   

# compiled with matlab R2022b so MCR main is v913. Needs to change if different MCR is used.
export LD_LIBRARY_PATH=/share/cluster/apps/MATLAB/R2022b/runtime/glnxa64:/share/cluster/apps/MATLAB/R2022b/bin/glnxa64:/share/cluster/apps/MATLAB/R2022b/sys/os/glnxa64:/share/cluster/apps/MATLAB/R2022b/sys/opengl/lib/glnxa64

export JOB_DIR=$PWD
export NEUROMINER=/ndl/NM/NeuroMinerMCCMain_1.1_v913/for_testing
export ACTION=oocv
read -e -p 'Path to NM structure: ' datpath
if [ ! -f $datpath ]; then
 	echo $datpath' not found.'
 	exit 
fi

read -e -p 'Path to job directory ['$JOB_DIR']: ' tJOB_DIR
if [ "$tJOB_DIR" != '' ]; then
	if [ -d $tJOB_DIR ]; then 
		export JOB_DIR=$tJOB_DIR
	else
		echo $tJOB_DIR' not found.'
		exit
	fi
fi 

read -e -p 'Change path to compiled NM directory ['$NEUROMINER']: ' tNEUROMINER
if [ "$tNEUROMINER" != '' ]; then     
  if [ -d $tNEUROMINER ]; then  
    export NEUROMINER=$tNEUROMINER
  else
    echo $tNEUROMINER' not found.'
    exit
  fi    
fi

read -p 'Provide your email address: ' EMAIL
echo '-----------------------'
echo 'PATH definitions:'
echo 'LOG directory: '$JOB_DIR
echo 'NeuroMiner directory: '$NEUROMINER
echo '-----------------------'
read -p 'Index to analysis container (NM.analysis{<index>}): ' analind
if [ "$analind" = '' ] ; then
	echo 'An analysis index is mandatory! Exiting program.'
	exit   
fi
read -p 'Index to independent data container (NM.OOCV{<index>}): ' oocvind
if [ "$oocvind" = '' ] ; then
	echo 'An OOCV data index is mandatory! Exiting program.'
	exit   
fi
export optmodelspath=NaN 
export optparamspath=NaN 
read -p 'Save optimized preprocessing parameters and models to disk for future use [ 1 = yes, 2 = no ]: ' saveparam
if [ "$saveparam" = '2' ] ; then
  read -p 'Load optimized preprocessing parameters and models from disk [ 1 = yes, 2 = no ]: ' loadparam
  if [ "$loadparam" = '1' ] ; then
    read -e -p 'Path to OptPreprocParam master file: ' optparamspath
    if [ ! -f $optparamspath ] ; then
	    echo $optparamspath' not found.'
	    exit
    fi
    read -e -p 'Path to OptModels master file: ' optmodelspath
    if [ ! -f $optmodelspath ] ; then
	    echo $optmodelspath' not found.'
	    exit
    fi
  fi
else
  loadparam=2
fi
read -p 'CV2 grid start row: ' CV2x1
read -p 'CV2 grid end row: ' CV2x2
read -p 'CV2 grid start column: ' CV2y1
read -p 'CV2 grid end column: ' CV2y2
read -p 'No. of SGE jobs: ' numCPU
read -p 'xxxx GB RAM / SLURM job: ' GB
mGB=$GB'G'
read -p 'Use OpenMP [yes = 1 | no = 0]: ' pLibsvm
if [ "$pLibsvm" = '1' ] ; then
	read -p 'Specify number of CPUs assigned to MATLAB job [4, 8, 16, 32]: ' pnum
	PMODE='#\$-pe omp '$pnum
else
	PMODE=''
	pnum=1
fi

read -p 'Submit jobs immediately (y): ' todo
for curCPU in $(seq $((numCPU)))
do
SD='_CPU'$curCPU
ParamFile=$JOB_DIR/Param_NM_$ACTION$SD
SLURMFile=$JOB_DIR/NM_$ACTION$SD
echo 'Generate parameter file: NM_'$ACTION$SD' => '$ParamFile
# Generate parameter file
cat > $ParamFile <<EOF
$NEUROMINER
$datpath
$analind
$oocvind
$saveparam
$loadparam
$optparamspath
$optmodelspath
$curCPU
$numCPU
$CV2x1
$CV2x2
$CV2y1
$CV2y2
EOF
cat > $SLURMFile <<EOF
#!/bin/bash
#SBATCH --job-name=nm$ACTION$SD
#SBATCH --output=$JOB_DIR/\%j.nm$ACTION$SD
#SBATCH --export=none
#SBATCH --cpus-per-task=$pnum
#SBATCH --mem=$mGB
$PMODE
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH
export OMP_NUM_THREADS=$pnum
cd $NEUROMINER 
./NeuroMinerMCCMain $ACTION $ParamFile
EOF
chmod u+x $SLURMFile
datum=`date +"%Y%m%d"`
if [ "$todo" = 'y' -o "$todo" = 'Y' ] ; then
sbatch $SLURMFile >> NeuroMiner_OOCV_$datum.log
fi
done