#!/bin/bash 
echo
echo '****************************************'
echo '*** NeuroMiner     	               ***'
echo '*** SGE joblist manager:             ***'
echo '*** Visualize models                 ***'
echo '*** (c) 2021 N. Koutsouleris         ***'
echo '****************************************'
echo '           VERSION 1.1                  '	
echo '****************************************'
echo   

# compiled with matlab R2022a so MCR main is v912. Needs to change if different MCR is used.
export LD_LIBRARY_PATH=/opt/matlab/v912/runtime/glnxa64:/opt/matlab/v912/bin/glnxa64:/opt/matlab/v912/sys/os/glnxa64:/opt/matlab/v912/sys/opengl/lib/glnxa64
# Preload glibc_shim in case of RHEL7 variants
export LD_PRELOAD=/opt/matlab/R2022a/bin/glnxa64/glibc-2.17_shim.so

export JOB_DIR=$PWD
export NEUROMINER=/opt/NM/NeuroMinerMCCMain_1.1_v912/for_testing
export ACTION=visualize

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
read -p 'Is the selected analysis a multi-group analysis [ 1 = yes, 2 = no ] ' MULTI
if [ "$MULTI" = '1' ] ; then
   read -p 'Visualize at models at multi-group optima [ 1 = yes, 2 = no ] ' multiflag
else
   multiflag=2
fi
read -p 'Write CVR and sign-based significance maps for each CV2 partition [ 1 = yes, 2 = no ] ' writeCV2flag
export optmodelspath=NaN 
export optparamspath=NaN 
read -p 'Save optimized preprocessing parameters and models to disk for future use [ 1 = yes, 2 = no ] ' saveparam
if [ "$saveparam" = '2' ] ; then
  read -p 'Load optimized preprocessing parameters and models from disk [ 1 = yes, 2 = no ] ' loadparam
  if [ "$loadparam" = '1' ] ; then
    read -e -p 'Path to OptPreprocParam master file ' optparamspath
    if [ ! -f $optparamspath ] ; then
	    echo $optparamspath' not found.'
	    exit
    fi
    read -e -p 'Path to OptModels master file ' optmodelspath
    if [ ! -f $optmodelspath ] ; then
	    echo $optmodelspath' not found.'
	    exit
    fi
  fi
else
  loadparam=2
fi
read -p 'Operate at the CV1 level [ 1 = yes, 2 = no ] ' inpCV1flag
read -p 'CV2 grid start row: ' CV2x1
read -p 'CV2 grid end row: ' CV2x2
read -p 'CV2 grid start column: ' CV2y1
read -p 'CV2 grid end column: ' CV2y2
read -p 'No. of SGE jobs: ' numCPU
read -p 'Server to use [any=1, psy0cf20=2, mitnvp1-2=3]: ' sind
if [ "$sind" = '1' ]; then
        SERVER_ID='all.q'
        echo "WARNING: if it is a high RAM job then please use psy0cf20"
elif [ "$sind" = '2' ]; then
        SERVER_ID='psy0cf20'
        echo "Please estimate RAM accurately"
elif [ "$sind" = '3' ]; then
        SERVER_ID='mitnvp1-2'
        echo "WARNING: if it is a high RAM job then please use psy0cf20"
else
        echo "Enter a number between 1-3"
fi
read -p 'xxxx MB RAM / SGE job: ' MB
MB=$MB'M'
# read -p 'Matlab version [1 = default (R2009B) | 2 = matlab/R2007B | 3 = matlab/R2008A | 4 = matlab/R2009A]: ' matl
# if [ "$matl" = '1' ] ; then
# 	matl=matlab/R2009B
# elif [ "$matl" = '2' ] ; then
# 	matl=matlab/R2007B
# elif [ "$matl" = '3' ] ; then
# 	matl=matlab/R2008A
# elif [ "$matl" = '4' ] ; then
# 	matl=matlab/R2009A
# fi
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
SGEFile=$JOB_DIR/NM_$ACTION$SD
echo 'Generate parameter file: NM_'$ACTION$SD' => '$ParamFile
# Generate parameter file
cat > $ParamFile <<EOF
$NEUROMINER
$datpath
$analind
$multiflag
$saveparam
$loadparam
$writeCV2flag
$optparamspath
$optmodelspath
$inpCV1flag
$curCPU
$numCPU
$CV2x1
$CV2x2
$CV2y1
$CV2y2
EOF
cat > $SGEFile <<EOF
#!/bin/bash
#\$-o $JOB_DIR/\$JOB_IDnm$ACTION$SD -j y
#\$-N nm$ACTION$SD
#\$-S /bin/bash
#\$-M $EMAIL
#\$-m ae
#\$-l mem_total=$MB
#\$-q $SERVER_ID
$PMODE
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH
export LD_PRELOAD=$LD_PRELOAD
export OMP_NUM_THREADS=$pnum
cd $NEUROMINER 
./NeuroMinerMCCMain $ACTION $ParamFile
EOF
chmod u+x $SGEFile
datum=`date +"%Y%m%d"`
if [ "$todo" = 'y' -o "$todo" = 'Y' ] ; then
qsub $SGEFile >> NeuroMiner_VisModels_$datum.log
fi
done
