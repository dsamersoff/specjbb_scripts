#!/bin/bash
OPT_VERSION="2.02 2020-09-04"

# JAVA_HOME and JBB_HOME 
# that comes from the environment
# overrrides default values

if [ "x$JAVA_HOME" = "x" ]
then
JAVA_HOME="/opt/dsamersoff/jdk-14"
fi

if [ "x$JBB_HOME" = "x" ]
then
JBB_HOME="/opt/dsamersoff/specjbb2015-1.03a"
fi

# Use tail -f --pid=${pid} to display controller log
# Usefull in some cases, i.e. under jenkins 
# but might cause the script to stuck
TAIL_WAIT=Yes

# Number of Groups (TxInjectors mapped to Backend) to expect
# Support 0, 1, 2, 4 groups. 0 means composite
GROUP_COUNT=0

# Number of TxInjector JVMs to expect in each Group
TI_JVM_COUNT=1

# Memory usage
# Page number is not adjusted to group count and passed as is. Take care.
PAGES=400

# Use or not numactl 
# 1 or 2 sockets supported
# GROUPS 0 NUMA Yes means composite run bound to 1 socket
NUMA=No

# Benchmark options for Controller / TxInjector JVM / Backend
# Please use -Dproperty=value to override the default and property file value
# Please add -Dspecjbb.controller.host=$CTRL_IP (this host IP) to the benchmark options for the all components
# and -Dspecjbb.time.server=true to the benchmark options for Controller 
# when launching MultiJVM mode in virtual environment with Time Server located on the native host.
if [ $GROUP_COUNT -ge 1 ]
then
SPEC_OPTS_C="\
        -Dspecjbb.group.count=$GROUP_COUNT \
        -Dspecjbb.txi.pergroup.count=$TI_JVM_COUNT \
"
fi

SPEC_OPTS_C="$SPEC_OPTS_C \
        -Dspecjbb.controller.rtcurve.warmup.step=0.7 \
        -Dspecjbb.forkjoin.workers.Tier1=100 \
        -Dspecjbb.forkjoin.workers.Tier2=1 \
        -Dspecjbb.forkjoin.workers.Tier3=16 \
        -Dspecjbb.customerDriver.threads=64 \
	-Dsecjbb.heartbeat.threshold=900000
"

SPEC_OPTS_TI="\
"
        
SPEC_OPTS_BE="\
"

# Java options for Controller / TxInjector / Backend JVM
JAVA_OPTS_COMMON="\
        -server \
        -XX:+PrintFlagsFinal \
"	

JAVA_OPTS_TUNING="\
        -Xnoclassgc \
        -XX:+UseParallelGC \
        -XX:-UseAdaptiveSizePolicy \
        -XX:+AlwaysPreTouch \
        -XX:+UseBiasedLocking \
        -XX:+UseLSE \
        -XX:-UsePerfData \
        -XX:-UseNUMA \
        -XX:-UseNUMAInterleaving \
        -XX:InlineSmallCode=20k \
        -XX:CompileThreshold=1000 \
        -XX:+AvoidUnalignedAccesses \
        -XX:+UseSIMDForMemoryOps \
        -XX:-UseFPUForSpilling \
        -XX:-SegmentedCodeCache \
        -XX:MaxInlineLevel=15 \
"


JAVA_OPTS_C="${JAVA_OPTS_COMMON} \
             -XX:ParallelGCThreads=3 \
             -Xms2g  \
             -Xmx2g  \
             -Xmn1536m \
"

JAVA_OPTS_TI="${JAVA_OPTS_COMMON} \
             -XX:ParallelGCThreads=3 \
             -Xms2g  \
             -Xmx2g  \
             -Xmn1536m \
"

pages=$PAGES
page_sz=512
mem_max=$(($pages * $page_sz))
mem_young=$(($mem_max - 10 * $page_sz))
mem_max+="m"
mem_young+="m"

JAVA_OPTS_BE="${JAVA_OPTS_COMMON} \
              ${JAVA_OPTS_TUNING} \
             -XX:ParallelGCThreads=56 \
             -Xmx$mem_max \
             -Xms$mem_max  \
             -Xmn$mem_young \
             -XX:SurvivorRatio=130 \
             -XX:TargetSurvivorRatio=66 \
             -XX:MaxTenuringThreshold=16 \
"


# Optional arguments for multiController / TxInjector / Backend mode 
# For more info please use: java -jar specjbb2015.jar -m <mode> -h
MODE_ARGS_C=""
MODE_ARGS_TI=""
MODE_ARGS_BE=""

# ----- Reporting ----------------
# Nothing to edit below this line
# ---------------------------------

echo "VERSION: $OPT_VERSION" > options.txt
echo "JAVA_HOME: $JAVA_HOME" >> options.txt
echo "GROUP_COUNT: $GROUP_COUNT" >> options.txt
echo "PAGES: $PAGES" >> options.txt
echo "NUMA: $NUMA" >> options.txt
echo "YOUNG: $mem_young" >> options.txt
echo "NUM_OF_RUNS: $NUM_OF_RUNS" >> options.txt
echo "$SPEC_OPTS_C"  | sed -e 's/ \+/\nSPEC_OPTS_Cx: /g' >> options.txt 
echo "$JAVA_OPTS_C"  | sed -e 's/ \+/\nJAVA_OPTS_Cx: /g' >> options.txt 
echo "$JAVA_OPTS_TI" | sed -e 's/ \+/\nJAVA_OPTS_TI: /g' >> options.txt 
echo "$JAVA_OPTS_BE" | sed -e 's/ \+/\nJAVA_OPTS_BE: /g' >> options.txt 

# END of OPTIONS