DATA_SOURCE = config.get("data_source", {})
DATA_SOURCE_MODE = DATA_SOURCE.get("mode", "local")
if DATA_SOURCE_MODE not in {"local", "ena_stage"}:
    raise ValueError("data_source.mode must be 'local' or 'ena_stage'")

REPO_ROOT = os.path.abspath(os.path.join(workflow.basedir, "../.."))


def config_bool(value):
    if isinstance(value, bool):
        return value
    return str(value).lower() in {"1", "true", "yes", "y"}


STAGE_READS = DATA_SOURCE_MODE == "ena_stage"
DATA_SOURCE_DOWNLOADER = DATA_SOURCE.get("downloader", "curl")
DATA_SOURCE_RETRIES = int(DATA_SOURCE.get("retries", 3))
KEEP_STAGED_READS = config_bool(DATA_SOURCE.get("keep_staged", False))
STAGE_DIR = DATA_SOURCE.get("stage_dir", os.path.join(output_dir, "staged_reads"))
MT_CONFIG = config.get("metatranscriptomics", {})
MT_STAGE_RETRIES = int(MT_CONFIG.get("stage_retries", DATA_SOURCE_RETRIES))
MT_STAGE_RETRY_DELAY_MINUTES = int(MT_CONFIG.get("stage_retry_delay_minutes", 60))
MT_STAGE_RETRY_DELAY_SECONDS = MT_STAGE_RETRY_DELAY_MINUTES * 60
MT_STAGE_RUNTIME_MINUTES = MT_STAGE_RETRY_DELAY_MINUTES * max(MT_STAGE_RETRIES - 1, 0) + 420

MG_R1_STAGE_PATTERN = os.path.join(STAGE_DIR, "metagenomics", "{sample}", "{sample}_R1.fastq.gz")
MG_R2_STAGE_PATTERN = os.path.join(STAGE_DIR, "metagenomics", "{sample}", "{sample}_R2.fastq.gz")
MT_R1_STAGE_PATTERN = os.path.join(STAGE_DIR, "metatranscriptomics", "{sample}", "{sample}_R1.fastq.gz")
MT_R2_STAGE_PATTERN = os.path.join(STAGE_DIR, "metatranscriptomics", "{sample}", "{sample}_R2.fastq.gz")


def maybe_temp(path):
    return path if KEEP_STAGED_READS else temp(path)


def optional_sample_value(sample, column):
    if column not in samples.columns:
        return ""
    value = samples.at[sample, column]
    if pd.isna(value):
        return ""
    return str(value)


def resolve_read_input(wildcards, column, staged_pattern):
    if STAGE_READS:
        return staged_pattern.format(sample=wildcards.sample)
    return samples.at[wildcards.sample, column]
