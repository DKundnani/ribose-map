#!/usr/bin/env bash

#Alli Gombolay, 11/2018
#Calculate counts of rAMP, rCMP, rGMP, and rUMP

######################################################################################################################################################

output=$repository/results/$sample/count$quality
rm -rf $output; mkdir -p $output

######################################################################################################################################################

for file in $output/$sample.bed; do

		for region in "nucleus" "mitochondria"; do

			#Separate BED file by oraganelle
			if [ $region == "nucleus"]; then
				#Get nucleotide for each chromosomal coordinate			
				grep -wvE 'chrM' $file > $output/$sample.$region.bed | bedtools getfasta -s -fi $fasta -bed - | grep -v '>' > $output/$sample.$region.nucs.tab

			elif [ $region == "mitochondria"]; then
				#Get nucleotide for each chromosomal coordinate
				grep -wE 'chrM' $file > $output/$sample.$region.bed | bedtools getfasta -s -fi $fasta -bed - | grep -v '>' > $output/$sample.$region.nucs.tab
			fi

			A_Ribo=$(awk '$1 == "A" || $1 == "a"' $output/$sample.$region.nucs.tab | wc -l)
			C_Ribo=$(awk '$1 == "C" || $1 == "c"' $output/$sample.$region.nucs.tab | wc -l)
			G_Ribo=$(awk '$1 == "G" || $1 == "g"' $output/$sample.$region.nucs.tab | wc -l)
			U_Ribo=$(awk '$1 == "T" || $1 == "t"' $output/$sample.$region.nucs.tab | wc -l)
	
			RiboTotal=$(($A_Ribo + $C_Ribo + $G_Ribo + $U_Ribo))

			A_RiboFreq=$(echo "($A_Ribo)" | bc -l)
			C_RiboFreq=$(echo "($C_Ribo)" | bc -l)
			G_RiboFreq=$(echo "($G_Ribo)" | bc -l)
			U_RiboFreq=$(echo "($U_Ribo)" | bc -l)
	
			paste <(echo -e "A") <(echo "$A_RiboFreq") >> $output/$sample.$region.counts.tab
			paste <(echo -e "C") <(echo "$C_RiboFreq") >> $output/$sample.$region.counts.tab
			paste <(echo -e "G") <(echo "$G_RiboFreq") >> $output/$sample.$region.counts.tab
			paste <(echo -e "U") <(echo "$U_RiboFreq") >> $output/$sample.$region.counts.tab

		done
done

######################################################################################################################################################

#Create output file
echo -e "\tnucleus\t\tmitochondria" > $output/$sample.ribo-counts.tab
join -t $'\t' $output/$sample.nucleus.counts.tab $output/$sample.mitochondria.counts.tab >> $output/$sample.ribo-counts.tab

######################################################################################################################################################

#Remove temporary files
rm -f $output/*.temp{1,2}.tab $output/$sample.$region.bed
