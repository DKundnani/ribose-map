#!/usr/bin/env bash

#Author: Alli L. Gombolay
#Calculates genomic coordinates of rNMPs for ribose-seq, emRiboSeq, Alk-HydEn-seq, RHII-HydEn-seq, and Pu-seq

#############################################################################################################################

#Load config file
. "$1"

#Create output directory and remove any old files
output=$repository/results/$sample/coordinate$quality
rm -r $output; mkdir -p $output
			
#############################################################################################################################

if [[ ! $read2 ]]; then
	#Convert BAM file to BED and filter by quality score
	bedtools bamtobed -i $repository/results/$sample/alignment/$sample.bam | mawk -v "OFS=\t" -v q="$quality" '$5 >= q { print }' - > $output/reads.bed

elif [[ $read2 ]]; then
	#Same process but keep only first read in read pairs
	samtools view -b -f67 $repository/results/$sample/alignment/$sample.bam | bedtools bamtobed -i stdin | mawk -v "OFS=\t" -v q="$quality" '$5 >= q { print }' - > $output/reads.bed
fi

#############################################################################################################################

#Determine coordinates for each technique
if [[ $technique == "ribose-seq" ]]; then

	#Obtain coordinates of rNMPs depending on the strand of DNA and sort data
	mawk -v "OFS=\t" '{if ($6 == "-") print $1, ($3 - 1), $3, $4, $5, "+"; else if ($6 == "+") print $1, $2, ($2 + 1), $4, $5, "-";}' $output/reads.bed | sort -k1,1 -k2,2n -k 6 > $output/$sample.bed
	
elif [[ $technique == "emRiboSeq" ]]; then

	#Obtain coordinates of rNMPs depending on the strand of DNA and sort data
	mawk -v "OFS=\t" '{if ($6 == "-") print $1, $3, ($3 + 1), $4, $5, "+"; else if ($6 == "+") print $1, ($2 - 1), $2, $4, $5, "-";}' $output/reads.bed > $output/temporary.bed

	#Remove coordinates of rNMPs if the end position is greater than length of chromosome
	join -t $'\t' <(sort $(dirname $fasta)/$(basename $fasta .fa).chrom.sizes) <(sort $output/temporary.bed) | mawk -v "OFS=\t" '$3 >= 0 && $2 >= $4 { print $1, $3, $4, $5, $6, $7 }' | sort -k1,1 -k2,2n -k 6 > $output/$sample.bed
	
elif [[ $technique == "Alk-HydEn-seq" ]] || [[ $technique == "Pu-seq" ]]; then
	
	#Obtain coordinates of rNMPs depending on the strand of DNA and sort data
	mawk -v "OFS=\t" '{if ($6 == "+") print $1, ($2 - 1), $2, $4, $5, "+"; else if ($6 == "-") print $1, $3, ($3 + 1), $4, $5, "-";}' $output/reads.bed > $output/temporary.bed
	
	#Remove coordinates of rNMPs if the end position is greater than length of chromosome
	join -t $'\t' <(sort $(dirname $fasta)/$(basename $fasta .fa).chrom.sizes) <(sort $output/temporary.bed) | mawk -v "OFS=\t" '$3 >= 0 && $2 >= $4 { print $1, $3, $4, $5, $6, $7 }' | sort -k1,1 -k2,2n -k 6 > $output/$sample.bed

elif [[ $technique == "RHII-HydEn-seq" ]]; then

	#Obtain coordinates of rNMPs depending on the strand of DNA and sort data
	mawk -v "OFS=\t" '{if ($6 == "+") print $1, $2, ($2 + 1), $4, $5, "+"; else if ($6 == "-") print $1, ($3 - 1), $3, $4, $5, "-";}' $output/reads.bed | sort -k1,1 -k2,2n -k 6 > $output/$sample.bed
	
fi

#Calculate raw and normalized (per 100) counts of rNMPs (must sort data before using uniq command)
cut -f1,2,3,6 $output/$sample.bed | uniq -c - | mawk -v "OFS=\t" '{print $2, $3, $4, ".", ".", $5, $1}' > $output/$sample.tab

#############################################################################################################################

#Remove temporary files
rm -f $output/reads.bed $output/temporary.bed

#Print status
echo "Status: Coordinate Module for $sample is complete"
