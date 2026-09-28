#!/bin/bash -l

set -euo pipefail

SMK_FILE="workflows/metatranscriptomics/preprocessing.smk"
SMK_CONFIG="config/airport_surveillance_config.yml"
SMK_JOBS=200

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../snakemake9_common.sh"
