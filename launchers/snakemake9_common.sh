#!/bin/bash

set -euo pipefail

SMK_ARG="${1:-}"
SMK_PROFILE="${SMK_PROFILE:-profiles/slurm-ibex}"
SMK_CONDA_PREFIX="${SMK_CONDA_PREFIX:-/ibex/user/naras0c/conda-environments/}"
SMK_ENV_NAME="${SMK_ENV_NAME:-snakemake_env}"

case "${SMK_ARG}" in
    "--dry-run") echo "Performing dry-run" ;;
    "--touch") echo "Touching files" ;;
    "--unlock") echo "Unlocking analysis folders" ;;
    "") echo "Launching analysis" ;;
    *) echo "Error: unexpected argument: ${SMK_ARG}"; exit 1 ;;
esac

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "${SMK_ENV_NAME}"

if ! python -c 'import importlib.util, sys; sys.exit(0 if importlib.util.find_spec("snakemake_executor_plugin_slurm") else 1)' ; then
    cat >&2 <<'EOF'
Error: snakemake_env does not include the Snakemake SLURM executor plugin.

Install it before launching cluster jobs:
  conda install -n snakemake_env -c conda-forge -c bioconda snakemake-executor-plugin-slurm
EOF
    exit 2
fi

mkdir -p slurm

CMD=(snakemake)
if [[ -n "${SMK_ARG}" ]]; then
    CMD+=("${SMK_ARG}")
fi
CMD+=(
    --profile "${SMK_PROFILE}"
    --configfile "${SMK_CONFIG}"
    --conda-prefix "${SMK_CONDA_PREFIX}"
    --jobs "${SMK_JOBS}"
    --notemp
    --snakefile "${SMK_FILE}"
)

printf '%q ' "${CMD[@]}"
printf '\n'
"${CMD[@]}"
