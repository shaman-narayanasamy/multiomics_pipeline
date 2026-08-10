# Multiomics pipeline

Reusable Snakemake workflows for metagenomic and metatranscriptomic read
processing, assembly, binning, annotation, and quantification. Project-specific
sample sheets and configuration belong in the project that invokes the
pipeline; large inputs and outputs belong on project storage.

## Status

The reusable workflows are active. The checked-in `PRJEB13233` and airport
surveillance configurations are historical examples, while new projects should
start from `config/examples/` and keep localized paths in ignored config files.

PRJEB79569 uses this repository for upstream MG/MT processing. Manuscript-grade
statistics and figures are maintained separately in
`phage_uv_ecology_analysis`.

## Input modes

Preprocessing supports two read-input modes:

- `local`: sample-sheet read columns point to files already present on the
  execution system;
- `ena_stage`: reads are staged from ENA or local URLs into a
  Snakemake-managed directory and removed after successful downstream use unless
  `data_source.keep_staged` is enabled.

A minimal staged-read example is available in
`config/examples/ena_staging_config.yml` with a matching example sample sheet.

Required sample-sheet columns are `sample_alias`, `MG_R1`, `MG_R2`, `MT_R1`,
and `MT_R2`. Optional provenance columns include condition, phase, cycle,
analysis group, biological sample alias, accessions, omics type, replicate
number, and read checksums.

## Resolve ENA metadata

The resolver converts an ENA study into the pipeline sample-sheet contract:

```sh
python scripts/ena/resolve_ena_study.py PRJEB79569 samples.tsv \
  --metadata sample_metadata.tsv \
  --require-library-strategy WGS
```

Run-level aliases remain unique. When several MT runs represent one physical
sample, the biological alias is retained so technical runs can be combined or
modeled downstream.

## Workflow entrypoints

Top-level workflows are organized under `workflows/`:

- `metagenomics/`: preprocessing and assembly;
- `metatranscriptomics/`: preprocessing and assembly;
- `coassembly.smk`: coassembly;
- `binning.smk` and `dereplication.smk`: MAG recovery;
- `annotation.smk`: genome annotation;
- `quantification_coverm.smk`: abundance quantification;
- `crispr_identification.smk`: CRISPR evidence generation.

Rules and environment definitions live under `rules/` and `envs/`.

## Run on SLURM

The canonical launchers use the Snakemake 9 SLURM executor profile in
`profiles/slurm-ibex/`. Localize the selected config, then start with a dry run:

```sh
bash launchers/sbatch_mt_preprocessing.sh --dry-run
```

The common launcher accepts environment overrides:

```sh
SMK_PROFILE=profiles/slurm-ibex \
SMK_CONDA_PREFIX=/path/to/conda-envs \
SMK_ENV_NAME=snakemake_env \
bash launchers/sbatch_mt_preprocessing.sh --dry-run
```

Available canonical launchers cover MG/MT preprocessing and assembly,
coassembly, binning, annotation, and CRISPR identification. Historical
airport-surveillance launchers remain isolated under
`launchers/airport_surveillance/`.

## Repository hygiene

Do not commit read data, workflow outputs, scheduler logs, rendered reports,
Snakemake state, or personal path overrides. Keep those in project storage and
use a local config matched by `.gitignore`.
