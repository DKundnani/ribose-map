#!/usr/bin/env bash

#Author: Alli Gombolay
#This program counts the number of rNMPs in each 2.5kb window of the reference genome

#COMMAND LINE OPTIONS

#Usage statement of the program
function usage () {
	echo "Usage: 4_Poisson.sh [-i] 'Sample' [-r] 'Reference' [-s] 'Subset' [-d] 'Directory' [-h]
	-i Sample name (FS1, etc.)
	-s Subset of genome (sacCer2, nuclear, chrM, etc.)
	-r Reference genome assembly version (sacCer2, etc.)
	-d Local directory (/projects/home/agombolay3/data/repository/Ribose-seq-Project)"
}

#Use getopts function to create the command-line options ([-i], [-s], [-r], [-d], and [-h])
while getopts "i:s:r:d:h" opt; do
    case $opt in
        #Specify input as arrays to allow multiple input arguments
        i ) sample=($OPTARG) ;;
	#Specify input as variable to allow only one input argument
	s ) subset=$OPTARG ;;
	r ) reference=$OPTARG ;;
	d ) directory=$OPTARG ;;
        #If user specifies [-h], print usage statement
        h ) usage ;;
    esac
done

#Exit program if user specifies [-h]
if [ "$1" == "-h" ]; then
        exit
fi

#Input files
bed=$directory/ribose-seq/reference/$reference.bed
sorted=$directory/ribose-seq/results/$reference/$sample/Coordinates/$subset/$sample.rNMP-coordinates.sorted.bed

#Output directories
output1=$directory/ribose-seq/reference/
output2=$directory/ribose-seq/results/$reference/$sample/Poisson

#Create directory if not present
mkdir -p $output1 $output2

#Output files
binned=$output2/$sample.binned.data.bed
windows=$output1/$reference.windows.bed

#Separate reference genome into 2.5 kb windows
bedtools makewindows -g $bed -w 2500 > $windows

#Select only data of interest
if [ $subset == "nuclear" ]; then
	#Select only nuclear DNA regions
	#Determine regions of BED files that intersect and count number of overlaps
	bedtools intersect -a $windows -b $sorted -c -sorted -nonamecheck | grep -v 'chrM' - > $binned
elif [ $subset == "chrM" ]; then
	#Select only mitochondrial DNA regions
	#Determine regions of BED files that intersect and count number of overlaps
	bedtools intersect -a $windows -b $sorted -c -sorted -nonamecheck | grep 'chrM' - > $binned
fi

total=0
proportions=()
counts0=$(awk '$4 == 0' FS15.trimmed.v1.binned.data.bed | wc -l)
echo $counts0
for i in {1..9}; do
	(( sum+=$(awk '$4 == ('$i')' FS15.trimmed.v1.binned.data.bed | awk '{sum+=$4} END{print sum}') ))
	counts1=$(awk '$4 == ('$i')' FS15.trimmed.v1.binned.data.bed | awk '{sum+=$4} END{print sum}')
	#echo $counts1
	
	total=$(($counts0+$sum))
	#echo $total
	proportions+=($(echo "scale = 12; ($counts1/$total)" | bc | awk '{printf "%.12f\n", $0}'))
	
done
( IFS=$'\n'; echo "${proportions[*]}" )
