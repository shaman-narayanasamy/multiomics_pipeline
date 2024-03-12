#!/bin/bash -l

# ARGS:
#   1: --dry-run for a snakemake dry-run, leave empty for execution

SMK_FILE="workflows/crispr_identification.smk"
SMK_JOBS=200 # USER SETTING: number of slurm jobs to be executed in parallel
SMK_ARG="$1" # ARG: add snakemake directives "--dry-run", "--touch" or "--unlock". Empty value will launch the analysis and other values will invoke an error.
SMK_CONFIG="config/PRJEB13233_config.yml"
SMK_SLURM_CONFIG="config/ibex_cluster_config.yml"
SMK_CLUSTER_ARGS="sbatch -p {cluster.partition} -N {cluster.nodes} -n {cluster.ntasks} -c {cluster.ncpus} -t {cluster.time} --mem {cluster.mem_gb} --mail-user {cluster.mail-user} --job-name {cluster.job-name} --output {cluster.stdout}"

# Ativate snakemake
#source ~/miniconda3/bin/activate snakemake

module load snakemake/7.32.3

case "${SMK_ARG}" in
    "--dry-run") echo "Performing dry-run"
        ;;
    "--touch") echo "Touching files"
        ;;
    "--unlock") echo "Unlocking analysis folders"
        ;;
    "") echo "No dry-run"
        ;;
    *) echo "Error: unexpected argument: ${SMK_ARG}"; exit 1
        ;;
esac

CMD="snakemake ${SMK_ARG} \
	-krp \
	--keep-remote \
	--configfile $SMK_CONFIG \
	--conda-prefix /ibex/user/naras0c/conda-environments/ \
	--use-conda \
	--conda-frontend mamba \
	--jobs $SMK_JOBS \
	--cluster-config ${SMK_SLURM_CONFIG} \
	--cluster \"${SMK_CLUSTER_ARGS}\"  \
	--cluster-cancel scancel \
	--notemp \
	-s ${SMK_FILE}"

echo $CMD
eval $CMD
