# flame_graph_helper.sh
Helper script to profile and generate flame graphs against a running Java process

## Purpose
Profiles a running java pid, collapses stack, automates stack dump, and generates FlameGraphs.
Relies on flamegraph-perf.pl, jmaps, and perf-map-agent

Defaults to google-chrome to open resulting .svg. Manually change in script

## usage

    flame_graph_helper.sh <command> <pid> <time>                                                                                                                                                                                          
    commands:
        help        Print this message
        install     Attempt to clone, build, and setup env relative to local folder
        list        Show all running java pids and command names
        profile     Profile and generate flame graphs for a running application

## Flow of work

    1) Clone perf-map-agent, used to map call traces in JAVA processes conveniently: https://github.com/jvm-profiling-tools/perf-map-agent
    2) FlameGraph repo: need perl scripts from this repo stored locally: https://github.com/brendangregg/FlameGraph
    3) jmaps: need jmaps from FlameGraph repo stored in local folder
    4) edit jmaps and set AGENT_HOME to perf-map-agent folder

## Detailed command reference

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

## Extra context / explanation of flow

    perf is used to capture kernel + application stack profiling
        defaults to 99hz interval. Can be manually modified below in -F param to 'perf record'
    jmaps is used to get symbol dumps for all running java processes by pid to /tmp
    perl scripts from FlameGraph collapse and format each stack as a single line
    Reference for more in-depth explanation: https://medium.com/netflix-techblog/java-in-flames-e763b3d32166

## Further Reading
[Java In Flames - Netflix tech blog](https://medium.com/netflix-techblog/java-in-flames-e763b3d32166)

[More on package flame graphs](http://www.brendangregg.com/blog/2017-06-30/package-flame-graph.html)

[Flame Graph reference](http://www.brendangregg.com/FlameGraphs/cpuflamegraphs.html)

