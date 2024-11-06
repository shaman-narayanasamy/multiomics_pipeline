import subprocess
import pandas as pd

tmp_dir = os.environ.get("tmp_dir", config['tmp_dir'])

## Define input directory
input_dir = config["input_dir"]["mt_assembly_input"]

## Define output directory
output_dir = os.path.join(config['output_dir'], "metatranscriptomics", "assembly")

## Define input files
# Read the sample table
samples = pd.read_table(config["data_table"], sep="\t", comment="#", dtype={"sample_alias": str})
samples.set_index("sample_alias", drop=False, inplace=True)

workdir:
    output_dir

include:
    '../../rules/metatranscriptomics/assembly/megahit.smk'

include:
    '../../rules/metatranscriptomics/assembly/penguin.smk'

include:
    '../../rules/metatranscriptomics/assembly/bwa.smk'

rule all:
     input:
        expand("{sample}/megahit_assembly/final.contigs.fa", sample = samples.index),
        expand("{sample}/penguin_assembly/final.contigs.fa", sample = samples.index),
        expand('{sample}/{sample}_metaT.reads.sorted.bam', sample = samples.index),
        expand('{sample}/{sample}_metaT.reads.sorted.flagstat.txt', sample = samples.index)
