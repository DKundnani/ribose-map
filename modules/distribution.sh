#!/usr/bin/env bash

#© 2016 Alli Gombolay
#Author: Alli Lauren Gombolay
#E-mail: alli.gombolay@gatech.edu

#1. Creates bedgraph files for forward and reverse strands
#2. Saves coverage of rNMPs per chromosome to separate files

#############################################################################################################################
#Load config file
. "$1"

#Create output directory
output=$repository/results/$sample/distribution; rm -rf $output; mkdir -p $output

#############################################################################################################################
#Save coverage of rNMPs per chromosome to separate files
for chromosome in $( awk '{print $1}' $repository/results/$sample/coordinates/reference.bed ); do
	grep -w "$chromosome" $repository/results/$sample/coordinates/$sample.normalized.bed > $output/$sample-$chromosome.tab
done

#Add trackline for forward strand to input into UCSC genome browser
echo "track type=bedGraph name="$sample-ForwardStrand" description="$sample-ForwardStrand" color=0,128,0 visibility=full" > $output/$sample-Forward.bg
		
#Add trackline for reverse strand to input into UCSC genome browser
echo "track type=bedGraph name="$sample-ReverseStrand" description="$sample-ReverseStrand" color=0,0,255 visibility=full" > $output/$sample-Reverse.bg
		
#Rearrange forward strand file so format is the same as bedgraph format
awk -v "OFS=\t" '$4 == "+" {print $1,$2,$3,$4}' $repository/results/$sample/coordinates/$sample.counts.tab >> $output/$sample-Forward.bg

#Rearrange reverse strand file so format is the same as bedgraph format
awk -v "OFS=\t" '$4 == "-" {print $1,$2,$3,$4}' $repository/results/$sample/coordinates/$sample.counts.tab >> $output/$sample-Reverse.bg

#############################################################################################################################
#Print status
echo "Status: Distribution Module for $sample is complete"
