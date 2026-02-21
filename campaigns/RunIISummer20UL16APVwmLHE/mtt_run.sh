# Run private production using RunIIFall18GS settings.
# Local example:
# source run.sh MyMCName /path/to/fragment.py 1000 1 1 filelist:/path/to/pileup/list.txt
# 
# Batch example:
# python crun.py MyMCName /path/to/fragment.py --outEOS /store/user/myname/somefolder --keepMini --nevents_job 10000 --njobs 100 --env
# See crun.py for full options, especially regarding transfer of outputs.
# Make sure your gridpack is somewhere readable, e.g. EOS or CVMFS.
# Make sure to run setup_env.sh first to create a CMSSW tarball (have to patch the DR step to avoid taking forever to uniqify the list of 300K pileup files)
echo $@

if [ -z "$1" ]; then
    echo "Argument 1 (name of job) is mandatory."
    return 1
fi
NAME=$1

if [ -z $2 ]; then
    echo "Argument 2 (fragment path) is mandatory."
    return 1
fi
CONFIG=$2
echo "Input arg 2 = $CONFIG"
CONFIG=$(readlink -e $CONFIG)
echo "After readlink fragment = $CONFIG"

if [ -z "$3" ]; then
    NEVENTS=100
else
    NEVENTS=$3
fi

if [ -z "$4" ]; then
    JOBINDEX=1
else
    JOBINDEX=$4
fi

RSEED=$((JOBINDEX * 4 + 1001)) # Space out seeds; Madgraph concurrent mode adds idx(thread) to random seed

echo "Fragment=$FRAGMENT"
echo "Job name=$NAME"
echo "NEvents=$NEVENTS"
echo "Random seed=$RSEED"

TOPDIR=$PWD

# wmLHE
export SCRAM_ARCH=slc7_amd64_gcc700
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_10_6_40/src ] ; then 
    echo release CMSSW_10_6_40 already exists
    cd CMSSW_10_6_40/src
    eval `scram runtime -sh`
else
    scram project -n "CMSSW_10_6_40" CMSSW_10_6_40
    cd CMSSW_10_6_40/src
    eval `scram runtime -sh`
fi

cd $CMSSW_BASE/src
scram b
cd $TOPDIR

cmsRun $FRAGMENT 
if [ ! -f "GEN-00000.root" ]; then
    echo "GEN-00000.root not found. Exiting."
    return 1
fi

