import os
import pandas as pd

# --- Setup Paths and Config ---
tmp_dir = os.environ.get("tmp_dir", config['tmp_dir'])
mt_reads_dir = config["input_dir"]["mt_assembly_input"]
mg_reads_dir = config["input_dir"]["mg_assembly_input"]
output_dir = os.path.join(config['output_dir'], "quantification")
catalogues = list(config["catalogues"].keys())

# --- Read Samples Table ---
samples = pd.read_table(
    config["data_table"], sep="\t", comment="#", dtype={"sample_alias": str}
).set_index("sample_alias", drop=False)
samples["omics"] = samples["omics"].str.strip().str.lower()
assert samples["omics"].isin(["metagenomics", "metatranscriptomics", "both"]).all()

# --- Compute Valid Sample-Omics Pairs ---
valid_sample_omics = [
    (sample, omics_type)
    for sample, row in samples.iterrows()
    for omics_type in (
        ["metagenomics", "metatranscriptomics"] if row["omics"] == "both" else [row["omics"]]
    )
]

# --- Precompute Output Files ---
all_alignments = [
    f"{catalogue}/alignments/{omics}/{sample}.{omics}.reads.sorted.bam"
    for sample, omics in valid_sample_omics
    for catalogue in catalogues
]

all_indexes = [
    f"indexes/{catalogue}/sequences.fa" for catalogue in catalogues
]

all_coverm = [
    f"{catalogue}/coverage/{omics}/coverm"
    for sample, omics in valid_sample_omics
    for catalogue in catalogues
]

all_gene_cov = [
    f"{catalogue}/gene_coverage/{omics}/{sample}_{omics}.tsv"
    for sample, omics in valid_sample_omics
    for catalogue in catalogues
    if "bed" in config["catalogues"][catalogue]
]

# --- Final Rule ---
rule all:
    input:
        all_alignments,
        all_indexes,
        all_coverm,
        all_gene_cov

# --- Include Rules ---
include: '../rules/quantification/coverm.smk'
include: '../rules/quantification/bwa.smk'

if any("bed" in config["catalogues"][cat] for cat in catalogues):
    include: '../rules/quantification/quantify_genes.smk'

# --- Set Working Directory ---
workdir:
    output_dir

