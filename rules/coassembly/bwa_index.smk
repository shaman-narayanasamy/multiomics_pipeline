rule bwa_index_assembly:
    input:
        fasta="{sample}/{sample}.coassembly_contigs.fa",
    output:
        "{sample}/{sample}.coassembly_contigs.fa.amb",
        "{sample}/{sample}.coassembly_contigs.fa.bwt",
        "{sample}/{sample}.coassembly_contigs.fa.pac",
        "{sample}/{sample}.coassembly_contigs.fa.ann",
        "{sample}/{sample}.coassembly_contigs.fa.sa"
    resources:
        mem_mb = 100000
    threads: 6
    conda: "../../envs/bwa_env.yml"
    benchmark: os.path.join(output_dir, "{sample}/benchmarks/bwa_indexing.txt")
    log: os.path.join(output_dir, "{sample}/logs/bwa_indexing.txt")
    shell:
        """
        bwa index {input.fasta}
        """

