rule generate_bedfile:
    input:
        coassembly_fasta="{sample}/{sample}.coassembly_contigs.fa",
    output:
        coassembly_bed="{sample}/{sample}.coassembly_contigs.fa.bed",
    conda: "../../../envs/bwa_env.yml"
    shell:
        """
	samtools faidx {input.coassembly_fasta}
        awk '{{print $1 "\t0\t" $2}}' {input.coassembly_fasta}.fai > {output.coassembly_bed}
        """

rule mosdepth_mg:
    input:
        coassembly_bed="{sample}/{sample}.coassembly_contigs.fa.bed",
        mg_bam = '{sample}/{sample}_metaG.reads.sorted.bam'
        mt_bam = '{sample}/{sample}_metaT.reads.sorted.bam'
    output:
    params:
        prefix = "{sample}/{sample}",
    conda: "../../../envs/mosdepth.yml"
    benchmark: 
    log: 
    shell:
        """
        mosdepth --fast-mode --by {input.coassembly_bed} {params.prefix}_metaG {input.mg_bam}
        mosdepth --fast-mode --by {input.coassembly_bed} {params.prefix}_metaT {input.mt_bam}
        """
