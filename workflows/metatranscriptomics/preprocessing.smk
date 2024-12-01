import subprocess
import pandas as pd

tmp_dir = os.environ.get("tmp_dir", config['tmp_dir'])

## Define output directory
output_dir = os.path.join(config['output_dir'], "metatranscriptomics", "preprocessing")

## Define input files
# Read the sample table
samples = pd.read_table(config["data_tables"]["all"], sep="\t", comment="#", dtype={"sample_alias": str})
samples = samples.dropna(subset=["MT_R1", "MT_R2"])
samples.set_index("sample_alias", drop=False, inplace=True)

workdir:
    output_dir

include:
    '../../rules/metatranscriptomics/preprocessing/trimmomatic.smk'

include:
    '../../rules/metatranscriptomics/preprocessing/sortmerna_index.smk'

include:
    '../../rules/metatranscriptomics/preprocessing/sortmerna_rrna.smk'

rule all:
     input:
        expand("{sample}/{sample}_R1.processed.fastq.gz", sample = samples.index),
        expand("{sample}/{sample}_R2.processed.fastq.gz", sample = samples.index),
        expand("{sample}/{sample}_SE.processed.fastq.gz", sample = samples.index),
        expand("{sample}/{sample}_R1.processed.rrna_removed.fastq.gz", sample = samples.index),
        expand("{sample}/{sample}_R2.processed.rrna_removed.fastq.gz", sample = samples.index),
        expand("{sample}/{sample}_SE.processed.rrna_removed.fastq.gz", sample = samples.index),
        expand("{sample}/{sample}_R1.processed.filtered.fastq.gz", sample = samples.index),
        expand("{sample}/{sample}_R2.processed.filtered.fastq.gz", sample = samples.index),
        expand("{sample}/{sample}_SE.processed.filtered.fastq.gz", sample = samples.index)
