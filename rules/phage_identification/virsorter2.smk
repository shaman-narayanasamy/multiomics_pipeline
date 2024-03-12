rule virsorter2_mt_contigs:
    input:
        fasta = os.path.join(mt_contigs_dir, "{sample}/megahit_assembly/final.contigs.fa")
    output:
        result = "{sample}/virsorter2/mt_contigs/final-viral-score.tsv",
        fasta = "{sample}/virsorter2/mt_contigs/final-viral-combined.fa"
    params:
        db = config["virsorter2"]["db"],
        threads = config["virsorter2"]["threads"]
    conda: "../../envs/virsorter2_env.yml"
    benchmark: "{sample}/virsorter2/mt_contigs/benchmarks/{sample}.txt"
    log: "{sample}/virsorter2/mt_contigs/logs/{sample}.txt"
    group: "virsorter2"
    shell:
       """
       virsorter run -w {wildcards.sample}/virsorter2/mt_contigs \
       -i {input.fasta} --include-groups "RNA" -j {params.threads} -d {params.db}
       """

rule virsorter2_coassembly_contigs:
    input:
        fasta = os.path.join(coassembly_dir, "{sample}/megahit_assembly/final.contigs.fa")
    output:
        result = "{sample}/virsorter2/coassembly/final-viral-score.tsv",
        fasta = "{sample}/virsorter2/coassembly/final-viral-combined.fa"
    params:
        db = config["virsorter2"]["db"],
        threads = config["virsorter2"]["threads"]
    conda: "../../envs/virsorter2_env.yml"
    benchmark: "{sample}/virsorter2/coassembly/benchmarks/{sample}.txt"
    log: "{sample}/virsorter2/coassembly/logs/{sample}.txt"
    group: "virsorter2"
    shell:
       """
       virsorter run -w {wildcards.sample}/virsorter2/coassembly \
       -i {input.fasta} --include-groups "dsDNAphage,NCLDV,RNA,ssDNA,lavidaviridae" \
       -j {params.threads} -d {params.db}
       """
