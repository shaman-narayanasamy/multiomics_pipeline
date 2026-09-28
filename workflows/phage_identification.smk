import subprocess
import pandas as pd

tmp_dir = os.environ.get("tmp_dir", config['tmp_dir'])

## Input input directory
mt_contigs_dir = config["input_dir"]["mt_contig_input"]
coassembly_dir = config["input_dir"]["coassembly_contig_input"]

## Define output directory
output_dir = os.path.join(config['output_dir'],  "phage_identification")

## Define input files
# Read the sample table
samples = pd.read_table(config["data_table"], sep="\t", comment = "#").set_index("sample_alias", drop=False)

workdir:
    output_dir

include:
    '../rules/phage_identification/genomad.smk'

include:
    '../rules/phage_identification/virsorter2.smk'

rule all:
     input:
        expand("{sample}/genomad/mt_contigs", sample = samples.index),
        expand("{sample}/genomad/coassembly", sample = samples.index),
        expand("{sample}/virsorter2/mt_contigs/final-viral-score.tsv", sample = samples.index),
        expand("{sample}/virsorter2/coassembly/final-viral-score.tsv", sample = samples.index)
