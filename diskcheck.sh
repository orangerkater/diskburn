#!/bin/bash

if [ $# -eq 0 ]
then
    echo "Usage: diskcheck.sh DEVICE..."
    exit 1
fi

DATE=$(date +%FT%R)
mkdir $DATE; cd $DATE

for prog in badblocks smartctl zcav pgrep gnuplot
do
    which $prog > /dev/null || echo "${prog} is not installed\!"
done

function thetime {
    date +%c
}

function smartcheck {
    local check_no=$1
    shift
    for disk in $@
    do
	local basename=$(basename $disk)
	echo "Running SMART #${check_no} of ${basename} on $(thetime)"
	smartctl -d sat --all $disk > ${basename}.smart.${check_no}
    done
}

function bbcheck {
    local mode=$1
    shift
    test $mode = "rw" && local opt="-w" || local opt=""
    echo "Running badblocks with mode ${mode} for all disks on $(thetime)"
    for disk in $@
    do
	local basename=$(basename $disk)
	badblocks ${opt} -o ${basename}.bb.${mode} ${disk}&
    done
    while pgrep 'badblocks' > /dev/null;do sleep 60;done
}

function zcavcheck {
    for disk in $@
    do
	local basename=$(basename $disk)
	echo "Running zcav for disk ${basename} on $(thetime)"
	zcav -l ${basename}.zcav ${disk}
    done
}

function draw_zcav {
    for disk in $@; do
	local basename=$(basename $disk)
	echo "unset autoscale x
set autoscale xmax
set autoscale xmin
unset autoscale y
set autoscale ymax
set autoscale ymin
set xlabel \"Position MB\"
set ylabel \"MB/s\"
set terminal png
set output \"${basename}.zcav.png\"
plot \"${basename}.zcav\" with dots" | gnuplot
    done
}

{
echo "Starting diskceck on $(thetime)"
echo "Disks checked are $@"
smartcheck 1 "$@"
bbcheck ro "$@"
smartcheck 2 "$@"
bbcheck rw "$@"
smartcheck 3 "$@"
zcavcheck "$@"
smartcheck 4 "$@"
draw_zcav "$@"
echo "Finished diskceck on $(thetime)"
} &> diskcheck.log

cd ..
