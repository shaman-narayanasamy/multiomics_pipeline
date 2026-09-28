# Multiomics pipeline

Snakemake workflows for metagenomic and metatranscriptomic read processing,
assembly, genome recovery, annotation and quantification.

## Inputs

The sample sheet contains `sample_alias`, `MG_R1`, `MG_R2`, `MT_R1` and `MT_R2`.
Condition, sampling phase, cleaning cycle and biological sample identifiers
can be retained as additional columns.

Reads can be supplied as local files or staged from ENA with `ena_stage`.
Start with a configuration under `config/examples/` and replace the input,
database and output paths for your system. The PRJEB13233 and airport
configurations describe earlier projects.

The ENA resolver prepares a sample sheet from a study accession:

```sh
python scripts/ena/resolve_ena_study.py PRJEB79569 samples.tsv \
  --metadata sample_metadata.tsv --require-library-strategy WGS
```

## Workflows

| Source | Task |
| --- | --- |
| `workflows/metagenomics/` | Metagenomic preprocessing and assembly |
| `workflows/metatranscriptomics/` | Metatranscriptomic preprocessing and assembly |
| `workflows/coassembly.smk` | Coassembly |
| `workflows/binning.smk` | Genome binning |
| `workflows/dereplication.smk` | Genome dereplication |
| `workflows/annotation.smk` | Genome annotation |
| `workflows/quantification_coverm.smk` | Abundance quantification |
| `workflows/crispr_identification.smk` | CRISPR identification |

Rules and Conda environments are in `rules/` and `envs/`. Launchers use the
Snakemake 9 SLURM executor profile under `profiles/slurm-ibex/`. Review the
selected configuration, then check the inputs with a dry run:

```sh
bash launchers/sbatch_mt_preprocessing.sh --dry-run
```

The launcher accepts `SMK_PROFILE`, `SMK_CONDA_PREFIX` and `SMK_ENV_NAME`.
Store reads, assemblies, alignments and workflow outputs outside this checkout.
