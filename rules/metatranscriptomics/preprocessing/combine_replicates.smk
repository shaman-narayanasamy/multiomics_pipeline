rule combine_mt_replicate_reads:
    input:
        r1=lambda wildcards: [
            os.path.join(sample, f"{sample}_R1.processed.filtered.fastq.gz")
            for sample in mt_replicates_for(wildcards.sample)
        ],
        r2=lambda wildcards: [
            os.path.join(sample, f"{sample}_R2.processed.filtered.fastq.gz")
            for sample in mt_replicates_for(wildcards.sample)
        ],
        se=lambda wildcards: [
            os.path.join(sample, f"{sample}_SE.processed.filtered.fastq.gz")
            for sample in mt_replicates_for(wildcards.sample)
        ]
    output:
        r1="combined/{sample}/{sample}_R1.processed.filtered.fastq.gz",
        r2="combined/{sample}/{sample}_R2.processed.filtered.fastq.gz",
        se="combined/{sample}/{sample}_SE.processed.filtered.fastq.gz"
    shell:
        """
        mkdir -p combined/{wildcards.sample}
        cat {input.r1} > {output.r1}
        cat {input.r2} > {output.r2}
        cat {input.se} > {output.se}
        """
