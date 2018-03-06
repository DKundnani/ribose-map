# Ribose-Map Bioinformatics Toolkit
## Toolkit for profiling the identity and distribution of rNMPs embedded in DNA
**© 2017 Alli Gombolay, Fredrik Vannberg, and Francesca Storici**  
**School of Biological Sciences, Georgia Institute of Technology**

## Modules:
1. **Alignment**: Align reads to the reference with Bowtie2 and de-depulicated based on UMI's UMI-tools
2. **Coordinates**: Locate genomic coordinates of rNMPs for ribose-seq, Pu-seq, emRibo-seq, or HydEn-seq
3. **Frequencies**: Calculate and visualize frequencies of nucleotides at and flanking sites of rNMP incorporation
4. **Distribution**: Visualize coverage of rNMPs across chromosomes and create bedgraph files for genome browser

## How to set up repository:
```
git clone https://github.com/agombolay/ribose-map/
```

* It is recommended to add the scripts to your $PATH  
* Mitochondria should be named chrM or MT in FASTA 

## Software dependencies:
### Required software:
* [Bowtie2](https://sourceforge.net/projects/bowtie-bio/files/bowtie2/2.3.1), [BEDtools](http://bedtools.readthedocs.io/en/latest/content/installation.html), [SAMtools](http://www.htslib.org/download/), and [R](https://cran.r-project.org/) (tools and ggplot2)

### Additional software:
* [cutadapt](http://cutadapt.readthedocs.io/en/stable/) is required if libraries contain a 5' molecular barcode
* [UMI-tools](https://github.com/CGATOxford/UMI-tools) is required if libraries contain a unique molecular identifier
  * Note: UMI-tools and cutadapt both require [Python](https://www.python.org/) to install and run

## Command usage:

|   Alignment Module      |   Coordinates Module      |   Frequencies Module      |   Distribution Module     |
| ----------------------- | ------------------------- | ------------------------- | ------------------------- |
| Alignment.sh config.sh  | Coordinates.sh config.sh  | Frequencies.sh config.sh  | Distribution.sh config.sh |
|                         |                           | Frequencies.R config.R    | Distribution.R config.R   |

* Note: The config.R file will be created automatically upon executing Frequencies.sh and/or Distribution.sh.

## Example config.sh file:
```
#Sample name
sample='sample1'

#Library prep
barcode='TCA'
umi='NNNNNNXXXNN'

#Sequencing technique
technique='ribose-seq'

#Ribose-Map directory
directory='/filepath/ribose-map'

#Reference genome info
index='/filepath/sacCer2'
reference='/filepath/sacCer2.fa'

#FASTQs files of reads
read1='/filepath/sample1_1.fastq'
read2='/filepath/sample1_2.fastq'
```
