#!/bin/bash
# Julie Shay
# This is a script for concatenating ART output into a single set of fastq files
set -e
set -u

if [ $# == 0 ]; then
	echo "This script will concatenate multiple ART output files into a set of combined fastq files"
	echo "It will concatenate fastq files with errors, as well as converting error free sam files"
	echo "to fastq files before concatenating those fastq files as well."
	echo "note also that the jdk module messes this script up."
	echo "Usage: $0 indir"
	echo "where indir is the input directory containing art output for multiple species"
	echo "This script will create the folder indir/combined and put the output files in there."
	exit 1
fi

indir=$1

outprefix=""

if ! (command -v picard); then
	echo "This program uses picard to convert the error free sam files into error free fastq files. Please add picard to the path."
	exit 1
fi

mkdir $indir/combined
touch $indir/combined/combined1.fq
touch $indir/combined/combined2.fq
touch $indir/combined/combined_errFree1.fq
touch $indir/combined/combined_errFree2.fq
# combine fastq files with error...
for fq in $(ls $indir/*1.fq)
do
	cat $fq >> $indir/combined/combined1.fq
	outprefix=${fq%1.fq}
	cat ${outprefix}2.fq >> $indir/combined/combined2.fq
done

# make error free fastq files
for sam in $(ls $indir/*_errFree.sam)
do
	outprefix=${sam%.sam}
	picard SamToFastq I=$sam F=${outprefix}1.fq F2=${outprefix}2.fq
done


# combined fastq files with no error. I realize that this is redundant.
for fq in $(ls $indir/*_errFree1.fq)
do
	cat $fq >> $indir/combined/combined_errFree1.fq
	outprefix=${fq%1.fq}
	cat ${outprefix}2.fq >> $indir/combined/combined_errFree2.fq
done
