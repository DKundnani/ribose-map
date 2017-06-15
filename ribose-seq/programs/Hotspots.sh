#!/usr/bin/env bash

#© 2016 Alli Gombolay
#Author: Alli Lauren Gombolay
#E-mail: alli.gombolay@gatech.edu
#This program calculates the coveage at each rNMP position

#Usage statement
function usage () {
	echo "Usage: Hotspots.sh [options]
		-s Sample name(s) (e.g., FS1, FS2, FS3)
		-r Reference genome (e.g., sacCer2, pombe, ecoli, mm9, hg38)
		-d Local user directory (e.g., /projects/home/agombolay3/data/repository)"
}

#Command-line options
while getopts "s:r:d:h" opt; do
    case "$opt" in
        #Allow multiple input arguments
        s ) sample=($OPTARG) ;;
	#Allow only one input argument
	r ) reference=$OPTARG ;;
	d ) directory=$OPTARG ;;
        #Print usage statement
        h ) usage ;;
    esac
done

#Exit program if [-h]
if [ "$1" == "-h" ]; then
        exit
fi

#Determine coordinates
for sample in ${sample[@]}; do

#############################################################################################################################
		#Create directory
		mkdir -p $directory/Ribose-Map/Results/$reference/$sample/Hotspots
		
		#Input file
		bam=$directory/Ribose-Map/Results/$reference/$sample/Alignment/$sample-MappedReads.bam

#############################################################################################################################
		#Calculate coverage at each rNMP position
		bedtools genomecov -d -3 -ibam $bam > temp.bed
		
		for subset in "mito" "nucleus"; do
	
			#Output file
			coverage=$directory/Ribose-Map/Results/$reference/$sample/Hotspots/$sample-Coverage.$subset.bed
	
			#Remove old file
			rm -f $directory/Ribose-Map/Results/$reference/$sample/Hotspots/$sample-Coverage.$subset.bed
	
			#Subset coordinates based on genomic region
			if [ $subset == "mito" ]; then
				grep -E '(chrM|MT)' temp.bed > $coverage
			elif [ $subset == "nucleus" ]; then
				grep -vE '(chrM|MT)' temp.bed > $coverage
			fi

		done
done
