rule fastp_trimming:
    input:
        read_1=lambda wildcards: resolve_read_input(wildcards, "MT_R1", MT_R1_STAGE_PATTERN),
        read_2=lambda wildcards: resolve_read_input(wildcards, "MT_R2", MT_R2_STAGE_PATTERN)
    output:
        paired_read_1 = "{sample}/{sample}_R1.processed.fastq.gz",
        paired_read_2 = "{sample}/{sample}_R2.processed.fastq.gz",
        unpaired_read_1 = temp("{sample}/{sample}_R1.unpaired.processed.fastq.gz"),
        unpaired_read_2 = temp("{sample}/{sample}_R2.unpaired.processed.fastq.gz"),
        unpaired_read = "{sample}/{sample}_SE.processed.fastq.gz",
        html = "{sample}/reports/{sample}.fastp.html",
        json = "{sample}/reports/{sample}.fastp.json"
    params:
        length_required=config.get("fastp", {}).get("length_required", 36),
        extra_args=config.get("fastp", {}).get("extra_args", "--detect_adapter_for_pe")
    resources: 
        cpus_per_task=12,
        runtime=2880
    conda: "../../../envs/fastp_env.yml"
    benchmark: os.path.join(output_dir, "{sample}/benchmarks/preprocessing_trimming.txt")
    log: os.path.join(output_dir, "{sample}/logs/preprocessing_trimming.txt")
    shell: 
        """ 
        fastp \
            --in1 {input.read_1:q} \
            --in2 {input.read_2:q} \
            --out1 {output.paired_read_1:q} \
            --out2 {output.paired_read_2:q} \
            --unpaired1 {output.unpaired_read_1:q} \
            --unpaired2 {output.unpaired_read_2:q} \
            --html {output.html:q} \
            --json {output.json:q} \
            --length_required {params.length_required} \
            --thread {resources.cpus_per_task} \
            {params.extra_args} \
            > {log:q} 2>&1

        gzip -c /dev/null > {output.unpaired_read:q}
        for unpaired in {output.unpaired_read_1:q} {output.unpaired_read_2:q}; do
            if [[ -s "$unpaired" ]]; then
                cat "$unpaired" >> {output.unpaired_read:q}
            fi
        done
        """
