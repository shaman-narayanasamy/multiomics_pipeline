import subprocess
import pandas as pd

tmp_dir = os.environ.get("tmp_dir", config['tmp_dir'])

## Input input directory
mt_reads_dir = config["input_dir"]["mt_assembly_input"]
mg_reads_dir = config["input_dir"]["mg_assembly_input"]
coassembly_dir = config["input_dir"]["coassembly_contig_input"]
phage_dirs = config["input_dir"]["crispr_link_input"]

## Define output directory
output_dir = os.path.join(config['output_dir'],  "crispr_identification")

## Define input files
# Read the sample table
samples = pd.read_table(config["data_table"], sep="\t", comment = "#").set_index("sample_alias", drop=False)

workdir:
    output_dir

include:
    '../rules/crispr_identification/crass.smk'

include:
    '../rules/crispr_identification/spacepharer.smk'

include:
    '../rules/crispr_identification/crisprcasfinder.smk'

rule all:
     input:
        expand("{sample}/crass_reads_out/crass.crispr", sample = samples.index),
        expand("{sample}/crass_contigs_out/crass.crispr", sample = samples.index),
        expand("{sample}/spacepharer/predictions.tsv", sample = samples.index),
        expand("crisprcasfinder/{sample}", sample = samples.index)
