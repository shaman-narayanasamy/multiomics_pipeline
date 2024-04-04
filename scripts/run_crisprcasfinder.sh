#! /bin/bash -l

module load singularity

APPDIR='/home/naras0c/repositories/github/CRISPRCasFinder'
IMAGE='/home/naras0c/repositories/github/CRISPRCasFinder/CrisprCasFinder.simg'
INPUT=$1
OUTDIR=$2
THREADS=$3

mkdir -p "$OUTDIR"
INPUT_BASEDIR=$(dirname "$INPUT")
INPUT_FILENAME=$(basename "$INPUT")
OUTPUT_BASENAME=$(basename "$INPUT_BASEDIR")

singularity exec -B $APPDIR \
	-B $INPUT_BASEDIR:/input \
	-B $OUTDIR:/output \
	$IMAGE \
	perl /usr/local/CRISPRCasFinder/CRISPRCasFinder.pl \
	-so /usr/local/CRISPRCasFinder/sel392v2.so \
	-cf /usr/local/CRISPRCasFinder/CasFinder-2.0.3 \
	-drpt /usr/local/CRISPRCasFinder/supplementary_files/repeatDirection.tsv \
	-rpts /usr/local/CRISPRCasFinder/supplementary_files/Repeat_List.csv \
	-cas -metagenome -def G -cpuP $THREADS -out /output/$OUTPUT_BASENAME -in /input/$INPUT_FILENAME


	#--no-home \
	#-B /ibex/user/naras0c/:/mnt \
