import subprocess
import pandas as pd

tmp_dir = os.environ.get("tmp_dir", config['tmp_dir'])

## Define input directories
mg_reads_dir = config["input_dir"]["mg_assembly_input"]
mt_reads_dir = config["input_dir"]["mt_assembly_input"]
mt_contigs_dir = config["input_dir"]["mt_contig_input"]

## Define output directory
output_dir = os.path.join(config['output_dir'], "coassembly")

## Define input files
# Read the sample table
sample_ids = pd.read_table(config["data_table"], sep="\t", comment = "#").set_index("sample_alias", drop=False)
samples = sample_ids.index

workdir:
    output_dir

include:
    '../rules/coassembly/megahit.smk'

include:
    '../rules/coassembly/bwa_index.smk'

include:
    '../rules/coassembly/bwa_mg.smk'

include:
    '../rules/coassembly/bwa_mt.smk'

include:
    '../rules/coassembly/coverm_contig.smk'

rule all:
     input:
        expand("{sample}/megahit_assembly/final.contigs.fa", sample = samples),
        expand("{sample}/{sample}.coassembly_contigs.fa", sample = samples),
        expand("{sample}/{sample}_metaG.reads.sorted.bam", sample = samples),
        expand("{sample}/{sample}_metaG.reads.sorted.bam.bai", sample = samples),
        expand("{sample}/{sample}_metaG.reads.sorted.flagstat.txt", sample = samples),
        expand("{sample}/{sample}_metaT.reads.sorted.bam", sample = samples),
        expand("{sample}/{sample}_metaT.reads.sorted.bam.bai", sample = samples),
        expand("{sample}/{sample}_metaT.reads.sorted.flagstat.txt", sample = samples),
        expand('{sample}/coverm/{sample}_coverage.out', sample = samples),
