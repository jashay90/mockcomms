#!/bin/bash
#$ -q all.q
#$ -cwd
#$ -V -j y
#$ -pe smp 3
#$ -N art
set -e
set -u

if [ $# == 0]; then
	echo "Given a set of mock community guidelines, this script just runs ART for each component of the mock community."
	echo "All of the components should be complete genomes."
	echo "Usage: $0 guidelines outdir err1 err2"
	echo "where guidelines is a tab-delimited file specifying what will go in the mock community,"
	echo "outdir is where all of the output files will go,"
	echo "err1 is the art error profile for R1 reads,"
	echo "and err2 is the art error profile for R2 reads"
	exit 1
fi
WFILE=$1
OUTFOLDER=$2
ERR1=$3
ERR2=$4
RLEN=250
BASES=10000000000
STDEV=10

halftotreads=$BASES/$RLEN
halftoreads=$(bc <<< "$BASES/($halftoreads*2)")
fsize=$(bc <<< "$RLEN*2")
reads=5

if ! (command -v art_illumina); then
	echo "This program uses art_illumina. Please add art_illumina to your path."
	exit 1
fi

mkdir $OUTFOLDER

while read line
do
	arr=($(echo $line | tr " " "\n"))	# note that the genus/species will have separate indeces
	reads=$(bc <<< "$halftotreads*${arr[4]}")
	reads=$(printf "%.0f" $reads)
	art_illumina -ef -p -1 $ERR1 -2 $ERR2 -sam -i ${arr[2]} -l $RLEN -c $reads -m $fsize -s $STDEV -o $OUTFOLDER/${arr[0]}${arr[1]}
done < <(tail -n "+2" $WFILE)
