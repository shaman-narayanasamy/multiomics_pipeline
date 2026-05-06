## Using the launcher

## Input data modes

The preprocessing workflows support two read-input modes:

- `local` keeps the original behavior. `MG_R1`, `MG_R2`, `MT_R1`, and `MT_R2`
  in the sample sheet are treated as paths that already exist on the file
  system.
- `ena_stage` stages read files just in time from ENA/local URLs into a
  Snakemake-managed temporary directory before Trimmomatic runs. Staged reads
  are deleted after downstream outputs are complete unless
  `data_source.keep_staged` is `true`.

Example config:

```yaml
data_source:
  mode: "ena_stage"
  stage_dir: "/path/to/hpc/scratch/PRJEB79569/staged_reads"
  keep_staged: false
  downloader: "curl"
  retries: 3
```

The required sample-sheet columns remain backward compatible:
`sample_alias`, `MG_R1`, `MG_R2`, `MT_R1`, and `MT_R2`. Optional columns such as
`condition`, `phase`, `cycle`, `analysis_group`, `run_accession`,
`sample_accession`, `study_accession`, and per-read checksum columns
(`MG_R1_md5`, `MG_R2_md5`, `MT_R1_md5`, `MT_R2_md5`) are preserved for
provenance and ENA staging validation.

ENA study metadata can be resolved into the pipeline sample-sheet shape:

```sh
python scripts/ena/resolve_ena_study.py PRJEB79569 metadata/PRJEB79569_multiomics_samples.tsv --metadata metadata/sample_metadata.tsv --require-library-strategy WGS
```

By default, `--omics auto` maps WGS/METAGENOMIC runs into `MG_R1`/`MG_R2`
and WGS/METATRANSCRIPTOMIC runs into `MT_R1`/`MT_R2`. It also emits unique
run-level `sample_alias` values because one biological sample can have multiple
ENA runs. The original biological alias is retained in
`biological_sample_alias`, with `omics` and `omics_replicate` marking MG/MT
assignment and repeated sequencing runs. For `PRJEB79569`, the MT data include
analytical sequencing replicates, so keep those as separate preprocessing rows
and combine or model them downstream.

To combine MT sequencing replicates after trimming and rRNA filtering, enable:

```yaml
metatranscriptomics:
  combine_replicates: true
  replicate_group_column: "biological_sample_alias"
```

Combined reads are written under
`metatranscriptomics/preprocessing/combined/<biological_sample_alias>/` and can
be used as the input directory for downstream MT assembly or quantification.
When replicate combining is enabled, the MT assembly and MT quantification
workflows derive their sample list from `biological_sample_alias` and
automatically read from the `combined/` subdirectory of
`input_dir.mt_assembly_input` or `input_dir.mt_quantification_input`.

Use `--require-library-strategy WGS` or another ENA strategy filter when a
study contains mixed assay types. The resolver warns when emitted runs are not
labelled as WGS, RNA-Seq, or transcriptomic because amplicon reads are not
suitable for shotgun rMAG recovery.

For projects with separate MG and MT ENA runs, generate separate sheets with
`--omics MG` and `--omics MT`, then merge the rows using the shared
`sample_alias` metadata contract before launching downstream workflows.

To download the data, we can use the following script:
```{sh}
scripts/download_data.sh <input metadata table> <download folder>
```
The input metadata table shoule contain the following tables:
sample_alias
MG_R1  
MG_R2   
MT_R1   
MT_R2

There are two launchers in the `launchers` directory:
```{sh}
sbatch_mt_preprocessing_smk7.32_scratch.sh
sbatch_mt_preprocessing_smk7.32_wekaio.sh
```
The reason there are two launchers is to help the ibex HPC team test the
performance of their WekaIO file system, which apparently is good for
reading/writing operations. I will revert back to a regular (single) launcher
once the system has been tested and the results relayed to the HPC team. To
that end, the the only difference between the launchers is that one of them
uses the `scratch`, BeeGFS filesystem as the temporary writing folder, while
the latter uses the WekaIO system as the temporary directory. The path of these
temporary folders have been encoded in the config file.

Dry run:
```{sh}
launchers/sbatch_mt_preprocessing_smk7.32_scratch.sh
```
NOTE: There are also other flags `--touch`

Launch and push to the background.
```{sh}
nohup launchers/sbatch_mt_preprocessing_smk7.32_scratch.sh > nohup_logs/mt_preprocessing_launch_$(date +'%Y%m%d_%H%M%S').log 2>&1 &
```

```{sh}
nohup launchers/sbatch_mt_assembly.sh > nohup_logs/mt_assembly_launch_$(date +'%Y%m%d_%H%M%S').log 2>&1 &
```

```{sh}
nohup launchers/sbatch_mg_preprocessing.sh > nohup_logs/mg_preprocessing_launch_$(date +'%Y%m%d_%H%M%S').log 2>&1 &
```

```{sh}
nohup launchers/sbatch_mg_assembly.sh > nohup_logs/mg_assembly_launch_$(date +'%Y%m%d_%H%M%S').log 2>&1 &
```

```{sh}
nohup launchers/sbatch_coassm.sh > nohup_logs/coassembly_launch_$(date +'%Y%m%d_%H%M%S').log 2>&1 &
```

```{sh}
nohup launchers/sbatch_phage.sh > nohup_logs/phage_launch_$(date +'%Y%m%d_%H%M%S').log 2>&1 &
```

```{sh}
nohup launchers/sbatch_crispr.sh > nohup_logs/crispr_launch_$(date +'%Y%m%d_%H%M%S').log 2>&1 &
```

```{sh}
nohup launchers/sbatch_annotation.sh > nohup_logs/annotation_launch_$(date +'%Y%m%d_%H%M%S').log 2>&1 &
```

NOTE: `nohup` is necessary when launching on the Ibex system


## Summarise data
```{sh}
cd /ibex/user/naras0c/ww_public_datasets/output/PRJEB13233/crispr_identification
mkdir -p summary_data
grep -Hv "^#" */spacepharer/predictions.tsv > summary_data/sparepharer_results.tsv
```
