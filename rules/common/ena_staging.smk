rule stage_mg_read_1:
    output:
        read=maybe_temp(MG_R1_STAGE_PATTERN)
    params:
        source=lambda wildcards: samples.at[wildcards.sample, "MG_R1"],
        md5=lambda wildcards: optional_sample_value(wildcards.sample, "MG_R1_md5"),
        downloader=DATA_SOURCE_DOWNLOADER,
        retries=DATA_SOURCE_RETRIES
    shell:
        """
        python {REPO_ROOT}/scripts/ena/stage_read.py \
            --source {params.source:q} \
            --output {output.read:q} \
            --md5 {params.md5:q} \
            --downloader {params.downloader:q} \
            --retries {params.retries}
        """


rule stage_mg_read_2:
    output:
        read=maybe_temp(MG_R2_STAGE_PATTERN)
    params:
        source=lambda wildcards: samples.at[wildcards.sample, "MG_R2"],
        md5=lambda wildcards: optional_sample_value(wildcards.sample, "MG_R2_md5"),
        downloader=DATA_SOURCE_DOWNLOADER,
        retries=DATA_SOURCE_RETRIES
    shell:
        """
        python {REPO_ROOT}/scripts/ena/stage_read.py \
            --source {params.source:q} \
            --output {output.read:q} \
            --md5 {params.md5:q} \
            --downloader {params.downloader:q} \
            --retries {params.retries}
        """


rule stage_mt_read_1:
    output:
        read=maybe_temp(MT_R1_STAGE_PATTERN)
    params:
        source=lambda wildcards: samples.at[wildcards.sample, "MT_R1"],
        md5=lambda wildcards: optional_sample_value(wildcards.sample, "MT_R1_md5"),
        downloader=DATA_SOURCE_DOWNLOADER,
        retries=DATA_SOURCE_RETRIES,
        retry_delay_seconds=MT_STAGE_RETRY_DELAY_SECONDS
    resources:
        runtime=MT_STAGE_RUNTIME_MINUTES
    retries: MT_STAGE_RETRIES
    shell:
        """
        python {REPO_ROOT}/scripts/ena/stage_read.py \
            --source {params.source:q} \
            --output {output.read:q} \
            --md5 {params.md5:q} \
            --downloader {params.downloader:q} \
            --retries {params.retries} \
            --retry-delay-seconds {params.retry_delay_seconds}
        """


rule stage_mt_read_2:
    output:
        read=maybe_temp(MT_R2_STAGE_PATTERN)
    params:
        source=lambda wildcards: samples.at[wildcards.sample, "MT_R2"],
        md5=lambda wildcards: optional_sample_value(wildcards.sample, "MT_R2_md5"),
        downloader=DATA_SOURCE_DOWNLOADER,
        retries=DATA_SOURCE_RETRIES,
        retry_delay_seconds=MT_STAGE_RETRY_DELAY_SECONDS
    resources:
        runtime=MT_STAGE_RUNTIME_MINUTES
    retries: MT_STAGE_RETRIES
    shell:
        """
        python {REPO_ROOT}/scripts/ena/stage_read.py \
            --source {params.source:q} \
            --output {output.read:q} \
            --md5 {params.md5:q} \
            --downloader {params.downloader:q} \
            --retries {params.retries} \
            --retry-delay-seconds {params.retry_delay_seconds}
        """
