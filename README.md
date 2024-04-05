## Using the launcher

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
