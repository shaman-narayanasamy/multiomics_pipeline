import os
import pandas as pd

# --- Setup Paths and Config ---
tmp_dir = os.environ.get("tmp_dir", config['tmp_dir'])
mt_reads_dir = config["input_dir"]["mt_assembly_input"]
mg_reads_dir = config["input_dir"]["mg_assembly_input"]
output_dir = os.path.join(config['output_dir'], "quantification")
catalogues = list(config["catalogues"].keys())
run_gene_coverage = config.get("run_gene_coverage", True)
run_contig_coverage = config.get("run_contig_coverage", True)

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
] if run_contig_coverage else []

all_indexes = [
    f"{catalogue}/indexes/sequences.fa" for catalogue in catalogues
] if run_contig_coverage else []

all_coverm = [
    f"{catalogue}/coverage/{omics}/coverm/output.tsv/output.tsv"
    for sample, omics in valid_sample_omics
    for catalogue in catalogues
] if run_contig_coverage else []

split_coverm_outputs = []

all_gene_cov = [
    f"{catalogue}/gene_coverage/{omics}/{sample}_{omics}.tsv"
    for sample, omics in valid_sample_omics
    for catalogue in catalogues
    if run_gene_coverage and "bed" in config["catalogues"][catalogue]
]

# --- Include Rules ---
if run_contig_coverage:
    include: '../rules/quantification/coverm.smk'
    include: '../rules/quantification/bwa.smk'

if run_gene_coverage and any("bed" in config["catalogues"][cat] for cat in catalogues):
    include: '../rules/quantification/quantify_genes.smk'

# --- Set Working Directory ---
workdir:
    output_dir

# --- Final Rule ---
rule all:
    input:
        all_alignments,
        all_indexes,
        all_coverm,
        all_gene_cov,
        split_coverm_outputs

