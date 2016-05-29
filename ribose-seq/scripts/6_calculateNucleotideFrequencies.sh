#! /usr/bin/env bash

#Author: Alli Gombolay
#This program calculates the frequencies of the nucleotides located in the assembled samples.
#Adapted from Jay Hesselberth's code located at https://github.com/hesselberthlab/modmap/tree/snake

# Mononucleotides, dinucleotides, and trinucleotides
sizes="1 2 3"

modes=("all" "only-mito" "no-mito" "only-2micron")

arguments=("" "--only-chrom chrM" "--ignore-chrom chrM" "--only-chrom 2micron")

#""= Entire genome ("all")
#"--only-chrom chrM"= Only chrM ("only-mito")
#"--only-chrom 2micron"=Only 2micron plasmid ("only-2micron")
#"--ignore-chrom chrM"= Nuclear chromosomes and 2micron plasmid ("no-mito")

input=$directory/ribose-seq/results/$samples/alignment

output=$directory/ribose-seq/results/$samples/nucleotideFrequencies

if [[ ! -d $output ]]; then
    mkdir -p $output
fi

offset_minimum=-100
offset_maximum=100

BAM=$input/$sample.bam

for index in ${!modes[@]};
do

        mode=${ignore_modes[$index]}
        
        arguments=${ignore_args[$index]}

        tables="$output/$sample.$mode.nucleotideFrequencies.tab"
        
        if [[ -f $tables ]];
        then
            rm -f $tables
        fi

        if [[ $mode == "only-mito" ]];
        then
            BackgroundFrequencies="$output/backgroundNucleotideFrequencies/chrM.nucleotide.frequencies.tab"
        
        elif [[ $mode == "only-2micron" ]];
        then
            BackgroundFrequencies="$output/backgroundNucleotideFrequencies/2micron.nucleotide.frequencies.tab"
        
        else
            BackgroundFrequencies="$output/backgroundNucleotideFrequencies/genome.nucleotide.frequencies.tab"
        fi

        #Signals need to be reverse complemented since sequence is reverse complement of the captured strand
        for size in $sizes;
        do
            python -m modmap.nuc_frequencies $BAM $FASTA --region-size $size $arguments --revcomp-strand \
            --background-freq-table $BackgroundFrequencies --offset-min $offset_minimum --offset-max $offset_maximum \
            --verbose >> $output
        done
    
done
