#!/usr/bin/env bash

#© 2016 Alli Gombolay
#Author: Alli Lauren Gombolay
#E-mail: alli.gombolay@gatech.edu
#This program aligns trimmed reads to reference genome using Bowtie2 and de-duplicates reads based on UMI
#Note1: FASTQ files must be located in users's FASTQ-Files folder (/LocalDirectory/Ribose-Map/FASTQ-Files)
#Note2: rNMP is the reverse complement of the 5' base of the sequenced read in FASTQ file

#Usage statement
function usage () {
	echo "Usage: Alignment.sh [options]
		-s Sample name(s) (e.g., FS1, FS2, FS3)
		-f Input Read 1 FASTQ filename (forward)
		-r Input Read 2 FASTQ filename (reverse)
		-u Length of UMI (e.g., NNNNNNNN or NNNNNNNNNNN)
		-b Barcode contained within UMI (e.g., ..TGA......)
		-t Type of Illumina Sequencing (e.g., SE = Single end, PE = Paired end)
		-i Basename of Bowtie2 index (e.g., sacCer2, pombe, ecoli, mm9, hg38, etc.)
		-m Minimum length of read to retain after trimming (e.g., 61 = 50 + NNNNNNNNNNN)
		-d Local user directory (e.g., /projects/home/agombolay3/data/repository/Ribose-Map)"
}

while getopts "s:u:m:i:t:f:r:b:d:h" opt; do
    	case "$opt" in
        	#Allow multiple input arguments
        	s ) sample=($OPTARG) ;;
		#Allow only one input argument
		u ) UMI=$OPTARG ;;
		m ) min=$OPTARG ;;
		i ) idx=$OPTARG ;;
		t ) type=$OPTARG ;;
		f ) read1=$OPTARG ;;
		r ) read2=$OPTARG ;;
		b ) barcode=$OPTARG ;;
		d ) directory=$OPTARG ;;
        	#Print usage statement
        	h ) usage ;;
    	esac
done

#Exit program if [-h]
if [ "$1" == "-h" ]; then
        exit
fi

#############################################################################################################################
#Input files
index=$directory/Indices/$idx
Fastq1=$directory/FASTQ-Files/$read1
Fastq2=$directory/FASTQ-Files/$read2

#Output directory
output=$directory/Results/$idx/$sample/Alignment

#Create directory
mkdir -p $output

#############################################################################################################################
for sample in ${sample[@]}; do

	#Remove old files
	rm -f $output/$sample.bam*

	#Single End Reads
	if [[ $type == "SE" ]]; then

#############################################################################################################################
		#Trim reads based on adapters and length
		trim_galore --length $min $Fastq1 -o $output
				
		#Reverse complement reads to obtain reads of interest
		cat $output/${sample}_trimmed.fq | seqtk seq -r - > $output/Reverse.fq
	
		#Extract UMI from 3' ends of reads and append to read name
		umi_tools extract -I $output/Reverse.fq -p $UMI --3prime -v 0 -S $output/Read1.fq

#############################################################################################################################
		#Align reads to reference genome and save Bowtie2 statistics log file
		bowtie2 -x $index -U $output/Read1.fq 2> $output/Bowtie2.log -S $output/mapped.sam
			
		#Extract mapped reads, convert SAM file to BAM format, and sort BAM file
		samtools view -bS -F260 $output/mapped.sam | samtools sort - -o $output/sorted.bam
		
		#Index BAM file
		samtools index $output/sorted.bam
	
#############################################################################################################################		
		#Remove PCR duplicates based on UMI and genomic start position and sort BAM file
		umi_tools dedup -I $output/sorted.bam -v 0 | samtools sort - -o $output/deduped.bam
			
		#Filter BAM file based on barcode
		samtools view -h $output/deduped.bam -o $output/deduped.sam
		grep -e "_$barcode" -e '^@' $output/deduped.sam > $output/filtered.sam
		samtools view $output/filtered.sam -bS | samtools sort -o $output/$sample.bam
						
		#Index BAM file
		samtools index $output/$sample.bam
			
#############################################################################################################################
		#Calculate percentage of reads that contain correct barcode
		x=$(echo "$(samtools view -c $output/$sample.bam)/$(samtools view -c $output/deduped.bam)")
			
		#Calculate percentage of reads that remain after de-duplication
		x=$(echo "$(samtools view -c $output/deduped.bam)/$(samtools view -c $output/sorted.bam)")
		
		#Save information about percentage of reads that contain correct barcode
		echo -e "Percentage: $(echo "$x*100" | bc -l | xargs printf "%.*f\n" 2)%" > $output/Barcode.log
			
		#Save information about percentage of reads that remain after de-duplication
		echo -e "Percentage: $(echo "$x*100" | bc -l | xargs printf "%.*f\n" 2)%" > $output/Duplicates.log
		
	fi

#############################################################################################################################
	#Paired End Reads
	if [[ $type == "PE" ]]; then

#############################################################################################################################
		#Trim reads based on adapters and quality
		trim_galore --paired --length $min $Fastq1 $Fastq2 -o $output
		
		#Reverse complement reads to obtain reads of interest
		cat $output/$sample*_val_1.fq | seqtk seq -r - > $output/temp1.fq
		cat $output/$sample*_val_2.fq | seqtk seq -r - > $output/Read2.fq
	
		#Extract UMI from 3' ends of reads and append to read name
		umi_tools extract -I $output/temp1.fq -p $UMI --3prime -v 0 -S $output/Read1.fq

#############################################################################################################################
		#Align reads to reference genome and save Bowtie2 statistics log file
		bowtie2 -x $index -1 $output/Read1.fq -2 $output/Read2.fq --no-mixed --no-discordant \
		>2 $output/Bowtie2.log -S $output/mapped.sam
		
		#Extract mapped reads, convert SAM file to BAM format, and sort BAM file
		samtools view -bS -f66 -F260 $output/mapped.sam | samtools sort - -o $output/sorted.bam
		
		#Index BAM file
		samtools index $output/sorted.bam
		
#############################################################################################################################
		#Remove PCR duplicates based on UMI and genomic start position and sort BAM file
		umi_tools dedup -I $output/sorted.bam -v 0 | samtools sort - -o $output/deduped.bam
		
		#Filter BAM file based on barcode
		samtools view -h $output/deduped.bam -o $output/deduped.sam
		grep -e "_$barcode" -e '^@' $output/deduped.sam > $output/filtered.sam
		samtools view $output/filtered.sam -bS | samtools sort -o $output/$sample.bam
		
		#Index BAM file
		samtools index $output/$sample.bam

#############################################################################################################################
		#Calculate percentage of reads that contain correct barcode
		x=$(echo "$(samtools view -c $output/$sample.bam)/$(samtools view -c $output/deduped.bam)")
		
		#Calculate percentage of reads that remain after de-duplication
		y=$(echo "$(samtools view -c $output/deduped.bam)/$(samtools view -c $output/sorted.bam)")
		
		#Save information about percentage of reads that contain correct barcode
		echo -e "Percentage: $(echo "$x*100" | bc -l | xargs printf "%.*f\n" 2)%" > $output/Barcode.log
		
		#Save information about percentage of reads that remain after de-duplication
		echo -e "Percentage: $(echo "$y*100" | bc -l | xargs printf "%.*f\n" 2)%" > $output/Duplicates.log
	
	fi

#############################################################################################################################
	#Notify user alignment step is complete for input sample
	echo "Trimming, alignment, and de-duplication of $sample is complete"

	#Remove temporary files
	#rm -f $output/${sample}_trimmed.fq $output/$sample*_val_*.fq $output/Reverse.fq $output/Read*.fq \
	#$output/mapped.sam $output/sorted.bam* $output/unmapped.bam $output/deduped.* $output/filtered.sam

done
