import os
import subprocess
import pandas as pd

tmp_dir = os.environ.get("tmp_dir", config['tmp_dir'])

## Define output directory
output_dir = os.path.join(config['output_dir'], "metatranscriptomics", "preprocessing")

## Define input files
# Read the sample table
samples = pd.read_table(config["data_table"], sep="\t", comment="#", dtype={"sample_alias": str})
samples = samples.dropna(subset=["MT_R1", "MT_R2"])
samples.set_index("sample_alias", drop=False, inplace=True)

MT_CONFIG = config.get("metatranscriptomics", {})
MT_REPLICATE_GROUP_COLUMN = MT_CONFIG.get("replicate_group_column", "biological_sample_alias")

include:
    '../common/read_staging.smk'

COMBINE_MT_REPLICATES = config_bool(MT_CONFIG.get("combine_replicates", False))
if COMBINE_MT_REPLICATES and MT_REPLICATE_GROUP_COLUMN not in samples.columns:
    raise ValueError(
        f"metatranscriptomics.combine_replicates requires column {MT_REPLICATE_GROUP_COLUMN!r}"
    )

if COMBINE_MT_REPLICATES:
    mt_combined_samples = sorted(samples[MT_REPLICATE_GROUP_COLUMN].dropna().astype(str).unique())
else:
    mt_combined_samples = []


def mt_replicates_for(sample):
    replicate_rows = samples[samples[MT_REPLICATE_GROUP_COLUMN].astype(str) == str(sample)]
    return replicate_rows["sample_alias"].astype(str).tolist()

workdir:
    output_dir

include:
    '../../rules/common/ena_staging.smk'

include:
    '../../rules/metatranscriptomics/preprocessing/trimmomatic.smk'

include:
    '../../rules/metatranscriptomics/preprocessing/sortmerna_index.smk'

include:
    '../../rules/metatranscriptomics/preprocessing/sortmerna_rrna.smk'

include:
    '../../rules/metatranscriptomics/preprocessing/combine_replicates.smk'

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
        expand("{sample}/{sample}_SE.processed.filtered.fastq.gz", sample = samples.index),
        expand("combined/{sample}/{sample}_R1.processed.filtered.fastq.gz", sample = mt_combined_samples),
        expand("combined/{sample}/{sample}_R2.processed.filtered.fastq.gz", sample = mt_combined_samples),
        expand("combined/{sample}/{sample}_SE.processed.filtered.fastq.gz", sample = mt_combined_samples)
