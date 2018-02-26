#!/bin/bash

usage () {
cat << USAGE
$0 <command> <pid> <time>
commands:
    help        Print this message
    install     Attempt to clone, build, and setup env relative to local folder
    list        Show all running java pids and command names
    profile     Profile and generate flame graphs for a running application

Generates flame graph against java process using FlameGraph, jmaps, and perf-map-agent
Defaults to google-chrome to open resulting .svg. Manually change in $0

Explanation of steps to setup local flame graph profiling pipeline:
    1) Clone perf-map-agent, used to map call traces in JAVA processes conveniently: https://github.com/jvm-profiling-tools/perf-map-agent
    2) FlameGraph repo: need perl scripts from this repo stored locally: https://github.com/brendangregg/FlameGraph
    3) jmaps: need jmaps from FlameGraph repo stored in local folder
    4) edit jmaps and set AGENT_HOME to perf-map-agent folder

Command reference to setup (flow of -i command):
    git clone https://github.com/jvm-profiling-tools/perf-map-agent;
    cd perf-map-agent; cmake .; make;
    cd out;
    git clone https://github.com/brendangregg/FlameGraph;
    cp FlameGraph/*.pl .;
    cp FlameGraph/jmaps .;
    # Add -XX:+PreserveFramePointer to your running environment for java application
    # Open jmaps, set AGENT_HOME to cloned location of perf-map-agent repo;
    # Start java application you want to profile, get it into the state where
    #   you want to profile it (couple minutes for HotSpot compilation to settle)
    # ./$0 <pid> <time_to_sample>

General explanation of flow:
    perf is used to capture kernel + application stack profiling
        defaults to 99hz interval. Can be manually modified below in -F param to 'perf record'
    jmaps is used to get symbol dumps for all running java processes by pid to /tmp
    perl scripts from FlameGraph collapse and format each stack as a single line
    Reference for more in-depth explanation: https://medium.com/netflix-techblog/java-in-flames-e763b3d32166
USAGE
    exit
}

show_pids() {
    ps aux | grep java | awk '{print "\n[ PID: ",$2,"]", $1=$2=$3=$4=$5=$6=$7=$8=$9=$10=""; print}'
}

if [ -z $1 ] || [ $1 = "help" ]; then
    usage
fi

if ! [ `command -v cmake` ]; then
    echo "installation of perf-map-agent requires cmake. aborting"
    usage
    exit
fi

if [ $1 = 'install' ]; then
    echo Installing...
    git clone https://github.com/jvm-profiling-tools/perf-map-agent;
    cd perf-map-agent; cmake .; make;
    cd out;
    git clone https://github.com/brendangregg/FlameGraph;
    cp FlameGraph/*.pl .;
    cp FlameGraph/jmaps .;
    cp ../../$0 .
    cd ../..
    echo -e
    echo "$(tput setaf 7)$(tput setab 1)>-----[MANUAL STEPS REQUIRED]-----<$(tput sgr 0)"
cat << MANUAL

    1) cd to perf-map-agent/out
    2) In file `pwd`/perf-map-agent/out/jmaps, replace the line:
        AGENT_HOME=*
    with:
        AGENT_HOME=`pwd`/perf-map-agent
    (TODO): automate this
    3) Add -XX:+PreserveFramePointer to your running environment for java application
    4) Start Java application
    5) ./$0 <pid> <time>

MANUAL
    echo "$(tput setaf 7)$(tput setab 1)>-----[MANUAL STEPS REQUIRED]-----<$(tput sgr 0)"
    exit
fi

if [ $1 = 'list' ]; then
    show_pids
    exit
fi

needs_exit=0

if ! [[ -e "jmaps" ]]; then
    echo "missing jmaps in local folder. Download from <insert_url_here>"
    needs_exit=1
fi

if ! [[ -e "stackcollapse-perf.pl" ]] || ! [[ -e "flamegraph.pl" ]]; then
    echo "missing stackcollapse-perf.pl or flamegraph.pl in local folder. Download from <https://github.com/brendangregg/FlameGraph>"
    needs_exit=1
fi

if [ $needs_exit -eq 1 ]; then
    echo "(run with -h for detailed instructions on setup)"
    exit
fi

if [ -z $2 ]; then
    echo "(run with -h for detailed instructions on setup)"
    echo "usage: $0 profile <pid> <time_to_record>"
    exit
fi

if [ -z $3 ]; then
    echo "usage: $0 profile <pid> <time_to_record>"
    exit
fi

if [ $1 = "profile" ]; then
    echo Profiling pid $2 for $3 seconds...
    sudo perf record -F 99 -p $2 -a -g -- sleep $3
    sudo ./jmaps
    echo Generating flame graphs...
    sudo perf script > out.stacks
    sudo ./stackcollapse-perf.pl out.stacks | ./flamegraph.pl --color=java --hash > out.svg

    echo "output written to out.svg. Opening"
    google-chrome out.svg
    exit
fi

usage
