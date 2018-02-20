#!/usr/bin/env bash

#© 2016 Alli Gombolay
#Author: Alli Lauren Gombolay
#E-mail: alli.gombolay@gatech.edu

#1. Calculate frequencies of rNMP nucleotides
#2. Calculate frequencies of flanking nucleotides

#############################################################################################################################
#Load config file
. "$1"

#Create output directory and remove any old files
output=$directory/results/$sample/frequencies; rm -rf $output; mkdir -p $output

#Create R config file
echo "sample <- '$sample'; directory <- '$directory'" > $directory/config-$sample.R
#############################################################################################################################
for subset in "mito" "nucleus"; do

	#STEP 1: Calculate frequencies of reference genome
	
	#Create fasta index and BED file for reference genome
	samtools faidx $reference && cut -f 1,2 $reference.fai > $output/reference.bed

	#Subset FASTA file based on region
	if [[ $subset == "mito" ]]; then
		chr=$(awk '{print $1}' $output/reference.bed | grep -E '(chrM|MT)')
		samtools faidx $reference $chr > $output/temp.fa && samtools faidx $output/temp.fa
	elif [[ $subset == "nucleus" ]]; then
		chr=$(awk '{print $1}' $output/reference.bed | grep -vE '(chrM|MT)')
		samtools faidx $reference $chr > $output/temp.fa && samtools faidx $output/temp.fa
	fi

	#Calculate counts of each nucleotide
	A_Bkg=$(grep -v '>' $output/temp.fa | grep -o 'A' - | wc -l)
	C_Bkg=$(grep -v '>' $output/temp.fa | grep -o 'C' - | wc -l)
	G_Bkg=$(grep -v '>' $output/temp.fa | grep -o 'G' - | wc -l)
	T_Bkg=$(grep -v '>' $output/temp.fa | grep -o 'T' - | wc -l)
	
	#Calculate total number of nucleotides
	BkgTotal=$(($A_Bkg + $C_Bkg + $G_Bkg + $T_Bkg))
		
	#Calculate frequency of each nucleotide
	A_BkgFreq=$(echo "($A_Bkg + $T_Bkg)/($BkgTotal*2)" | bc -l)
	C_BkgFreq=$(echo "($C_Bkg + $G_Bkg)/($BkgTotal*2)" | bc -l)
	G_BkgFreq=$(echo "($G_Bkg + $C_Bkg)/($BkgTotal*2)" | bc -l)
	T_BkgFreq=$(echo "($T_Bkg + $A_Bkg)/($BkgTotal*2)" | bc -l)
		
	#Save background frequencies of dNMPs to TXT files
	echo $A_BkgFreq | xargs printf "%.*f\n" 5 > $output/A_Bkg.txt
	echo $C_BkgFreq | xargs printf "%.*f\n" 5 > $output/C_Bkg.txt
	echo $G_BkgFreq | xargs printf "%.*f\n" 5 > $output/G_Bkg.txt
	echo $T_BkgFreq | xargs printf "%.*f\n" 5 > $output/T_Bkg.txt

	#Combine dNMP frequencies into one file
	Bkg=$(paste $output/{A,C,G,T}_Bkg.txt)

#############################################################################################################################
	#STEP 2: Create and save file containing background dNMP frequencies
		
	#Add nucleotides to header line and background frequencies
	echo -e "A\tC\tG\tT" > "${reference%.*}"-Freqs.$subset.txt
	paste <(echo -e "$Bkg") >> "${reference%.*}"-Freqs.$subset.txt
			
#############################################################################################################################
	#STEP 3: Calculate frequencies of rNMPs in libraries
		
	#Subset and sort unique coordinates based on genomic region
	if [[ $subset == "mito" ]]; then
		uniq $directory/results/$sample/coordinates/$sample.bed | grep -E '(chrM|MT)' > $output/Coords.bed
	elif [[ $subset == "nucleus" ]]; then
		uniq $directory/results/$sample/coordinates/$sample.bed | grep -vE '(chrM|MT)' > $output/Coords.bed
	fi
	
	if [[ -s $output/Coords.bed ]]; then
	
		#Extract rNMP bases
		bedtools getfasta -s -fi $output/temp.fa -bed $output/Coords.bed | grep -v '>' > $output/Ribos.txt
	
		#Calculate counts of rNMPs
		A_Ribo=$(awk '$1 == "A"' $output/Ribos.txt | wc -l)
		C_Ribo=$(awk '$1 == "C"' $output/Ribos.txt | wc -l)
		G_Ribo=$(awk '$1 == "G"' $output/Ribos.txt | wc -l)
		U_Ribo=$(awk '$1 == "T"' $output/Ribos.txt | wc -l)
	
		#Calculate total number of rNMPs
		RiboTotal=$(($A_Ribo + $C_Ribo + $G_Ribo + $U_Ribo))
	
		#Calculate normalized frequency of each rNMP
		A_RiboFreq=$(echo "($A_Ribo/$RiboTotal)/$A_BkgFreq" | bc -l)
		C_RiboFreq=$(echo "($C_Ribo/$RiboTotal)/$C_BkgFreq" | bc -l)
		G_RiboFreq=$(echo "($G_Ribo/$RiboTotal)/$G_BkgFreq" | bc -l)
		U_RiboFreq=$(echo "($U_Ribo/$RiboTotal)/$T_BkgFreq" | bc -l)

		#Save normalized frequencies of rNMPs to TXT files
		echo $A_RiboFreq | xargs printf "%.*f\n" 5 > $output/A_Ribo.txt
		echo $C_RiboFreq | xargs printf "%.*f\n" 5 > $output/C_Ribo.txt
		echo $G_RiboFreq | xargs printf "%.*f\n" 5 > $output/G_Ribo.txt
		echo $U_RiboFreq | xargs printf "%.*f\n" 5 > $output/U_Ribo.txt

		#Combine rNMP frequencies into one file
		Ribo=$(paste $output/{A,C,G,U}_Ribo.txt)

#############################################################################################################################
		#STEP 4: Obtain coordinates/sequences of dNMPs +/- 100 bp from rNMPs

		#Obtain coordinates of flanking sequences and remove coordinates where start = end
		bedtools flank -i $output/Coords.bed -s -g $output/reference.bed -l 100 -r 0 | awk '$2 != $3' > $output/Up.bed
		bedtools flank -i $output/Coords.bed -s -g $output/reference.bed -l 0 -r 100 | awk '$2 != $3' > $output/Down.bed
	
		#Obtain nucleotide sequences flanking rNMPs using coordinates from above (reverse order of up)
		bedtools getfasta -s -fi $output/temp.fa -bed $output/Down.bed | grep -v '>' > $output/Down.txt
		bedtools getfasta -s -fi $output/temp.fa -bed $output/Up.bed | grep -v '>' | rev > $output/Up.txt 
			
#############################################################################################################################
		#STEP 5: Insert tabs between sequences of dNMPs +/- 100 bp from rNMPs
	
		#Insert tabs between each base for easier parsing
		cat $output/Up.txt | sed 's/.../& /2g;s/./& /g' > $output/Up.ext
		cat $output/Down.txt | sed 's/.../& /2g;s/./& /g' > $output/Down.ext

		#Save lists of dNMPs at each of the +/-100 positions in separate files
		for i in {1..100}; do
			awk -v field=$i '{ print $field }' $output/Up.ext > $output/$sample.Up.$i.txt
			awk -v field=$i '{ print $field }' $output/Down.ext > $output/$sample.Down.$i.txt
		done
		
		#while read line; do printf "%5s\n" "$line"; done < $output/Up.tab
		#while read line; do printf "%5s\n" "$line"; done < $output/Down.tab
		
#############################################################################################################################
		#STEP 6: Calculate frequencies of dNMPs +/- 100 base pairs from rNMPs

		for dir in "Up" "Down"; do
		
			#for i in {1..100}; do
			#'-v' = natural sort of #'s
			for file in $(ls -v $output/$sample.$dir.{1..100}.txt); do
		
				#Calculate count of each dNMP
				A_Flank=$(grep -o 'A' $file | wc -l)
				C_Flank=$(grep -o 'C' $file | wc -l)
				G_Flank=$(grep -o 'G' $file | wc -l)
				T_Flank=$(grep -o 'T' $file | wc -l)
				
				#A_Flank=$(awk -v field=$i '{ print $field }' $output/$dir.tab | grep -o 'A' | wc -l);
				#C_Flank=$(awk -v field=$i '{ print $field }' $output/$dir.tab | grep -o 'C' | wc -l);
				#G_Flank=$(awk -v field=$i '{ print $field }' $output/$dir.tab | grep -o 'G' | wc -l);
				#T_Flank=$(awk -v field=$i '{ print $field }' $output/$dir.tab | grep -o 'T' | wc -l);

				#Calculate total number of dNMPs
				FlankTotal=$(($A_Flank + $C_Flank + $G_Flank + $T_Flank))

				#Calculate normalized frequencies of dNMPs
				A_FlankFreq=$(echo "($A_Flank/$FlankTotal)/$A_BkgFreq" | bc -l)
				C_FlankFreq=$(echo "($C_Flank/$FlankTotal)/$C_BkgFreq" | bc -l)
				G_FlankFreq=$(echo "($G_Flank/$FlankTotal)/$G_BkgFreq" | bc -l)
				T_FlankFreq=$(echo "($T_Flank/$FlankTotal)/$T_BkgFreq" | bc -l)
		
				#Save normalized dNMPs frequencies to TXT files
				echo $A_FlankFreq | xargs printf "%.*f\n" 5 >> $output/A_$dir.txt
				echo $C_FlankFreq | xargs printf "%.*f\n" 5 >> $output/C_$dir.txt
				echo $G_FlankFreq | xargs printf "%.*f\n" 5 >> $output/G_$dir.txt
				echo $T_FlankFreq | xargs printf "%.*f\n" 5 >> $output/T_$dir.txt
		
				#Combine dNMP frequencies into one file per location
				if [[ $dir == "Up" ]]; then
					#Print upstream frequencies in reverse order
					Up=$(paste $output/{A,C,G,T}_Up.txt | tac -)
				elif [[ $dir == "Down" ]]; then
					Down=$(paste $output/{A,C,G,T}_Down.txt)
				fi
				
			done
		done
	
#############################################################################################################################
		#STEP 7: Create and save dataset file containing nucleotide frequencies
			
		#Add nucleotides to header line
		echo -e "\tA\tC\tG\tU/T" > $output/$sample-Frequencies.$subset.tab
			
		#Add positions and frequencies of nucleotides in correct order to create dataset
		paste <(echo "$(seq -100 1 100)") <(cat <(echo "$Up") <(echo "$Ribo") <(echo "$Down")) \
		>> $output/$sample-Frequencies.$subset.tab
						
#############################################################################################################################
		#Print status
		echo "Status: Frequencies module for $sample ($subset) is complete"
					
	fi
	#Remove temp files
	rm -f $output/*.{txt,bed,fa,fa.fai}

done
