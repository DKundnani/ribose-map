#!/usr/bin/env bash

#© 2016 Alli Gombolay
#Author: Alli Lauren Gombolay
#E-mail: alli.gombolay@gatech.edu

#Usage statement
function usage () {
	echo "Usage: pre-process.sh [options]
		Required:
		-d Ribose-Map directory
		-s Name of sequenced library
		-f Input Read 1 FASTQ filename
		-r Input Read 2 FASTQ filename"
}

while getopts "h:f:r:s:d" opt; do
	case "$opt" in
		h ) usage ;;
		f ) read1=$OPTARG ;;
		r ) read2=$OPTARG ;;
		s ) sample=$OPTARG ;;
		d ) directory=$OPTARG ;;
	esac
done

#############################################################################################################################
#Input files
fastq1=$directory/fastqs/$read1
fastq2=$directory/fastqs/$read2

#Remove old files
rm -f $output/*_trimmed{1,2}.fq

#############################################################################################################################
#Single-end reads
fastqc $fastq1 -o $output
cutadapt $fastq1 -m 50 -a 'AGTTGCGACACGGATCTCTCA' -o $output/$sample_trimmed.fq

#Paired-end reads
fastqc $fastq1 $fastq2 -o $output
cutadapt $fastq1 $fastq2 -m 50 -a 'AGTTGCGACACGGATCTCTCA' -o $output/$sample_trimmed1.fq -p $output/$sample_trimmed2.fq