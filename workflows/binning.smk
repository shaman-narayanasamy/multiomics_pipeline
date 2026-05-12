import os
import subprocess
import pandas as pd

## Define input directory
#input_dir = config["input_dir"]["coassembly_contig_input"]

## Define output directory
output_dir = os.path.join(config['output_dir'],  "binning")

## Define input files
# Read the sample table
#samples = pd.read_table(config["data_table"], sep="\t", comment = "#").set_index("sample_alias", drop=False)
if "single_sample" in config:
    # Override with single fasta and sample
    print(f"Using single sample: {config['single_sample']['sample_alias']} with fasta: {config['single_sample']['fasta']}")
    samples = pd.DataFrame({
        "sample_alias": [config["single_sample"]["sample_alias"]],
        "R1": [config["single_sample"]["R1"]],
        "R2": [config["single_sample"]["R2"]],
        "SE": [config["single_sample"]["SE"]],
        "fasta": [config["single_sample"]["assembly_path"]]
    })
    samples.set_index(["sample_alias"], drop=False, inplace=True)
else:
    # Use the table by default
    samples = pd.read_table(config["data_table"], sep="\t", comment="#", dtype={"sample_alias": str})
    samples.rename(columns={"assembly_path": "fasta"}, inplace=True)  # Rename here
    samples = samples.dropna(subset=["sample_alias", "R1", "R2", "SE", "fasta"])
    samples.set_index("sample_alias", drop=False, inplace=True)

workdir:
    output_dir

include:
    '../rules/binning/contig_sorting.smk'

include:
    '../rules/binning/concoct.smk'

include:
    '../rules/binning/metabat2.smk'

include:
    '../rules/binning/maxbin2.smk'

include:
    '../rules/binning/vamb.smk'

include:
    '../rules/binning/semibin.smk'

include:
    '../rules/binning/marker_genes.smk'

include:
    '../rules/binning/contig_to_bin.smk'

include:
    '../rules/binning/bin_refinement.smk'

include:
    '../rules/binning/separate_bins.smk'

include:
    '../rules/binning/semibin_multi_sample.smk'

include:
    '../rules/binning/dereplication.smk'

rule all:
     input:
        'semibin_multi_sample/concatenated.fa',
        'semibin_multi_sample/binning.done',
        expand("{sample}/concoct/bins", sample = samples.index),
        expand("{sample}/metabat2.done", sample = samples.index),
        expand("{sample}/maxbin2.done", sample = samples.index),
        expand("{sample}/semibin.done", sample = samples.index),
        expand("{sample}/vamb.done", sample = samples.index),
        expand("{sample}/magscot/MAGScoT.refined.contig_to_bin.out", sample = samples.index),
        expand("{sample}/magscot", sample = samples.index),
        expand("{sample}/magscot_bins", sample = samples.index),
        expand("{sample}/DeepMicroClass/prokaryotes.fa", sample = samples.index),
        expand("{sample}/DeepMicroClass/eukaryotes.fa", sample = samples.index),
        expand("{sample}/DeepMicroClass/prokaryotic_viruses.fa", sample = samples.index),
        expand("{sample}/DeepMicroClass/eukaryotic_viruses.fa", sample = samples.index),
        expand("{sample}/DeepMicroClass/plasmids.fa", sample = samples.index),
        expand("{sample}/{sample}_metaG.reads.sorted.bam", sample = samples.index),
        'semibin_multi_sample/output',
        'semibin_multi_sample/binning.done',
        expand("semibin_multi_sample/contigs_to_bins/{sample}_contig_to_bin.tsv", sample = samples.index),
        "dereplication"
