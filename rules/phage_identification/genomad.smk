rule genomad_mt_contigs:
    input:
        fasta = os.path.join(mt_contigs_dir, "{sample}/megahit_assembly/final.contigs.fa")
    output:
        outdir = directory("{sample}/genomad/mt_contigs")
    params:
        db = config["genomad"]["db"],
        threads = config["genomad"]["threads"]
    conda: "../../envs/genomad_env.yml"
    benchmark: "{sample}/genomad/mt_contigs/benchmarks/{sample}.txt"
    log: "{sample}/genomad/mt_contigs/logs/{sample}.txt"
    group: "genomad"
    shell:
       """
       genomad end-to-end -t {params.threads} \
       --cleanup --restart {input.fasta} {output.outdir} {params.db}
       """

rule genomad_coassembly_contigs:
    input:
        fasta = os.path.join(coassembly_dir, "{sample}/megahit_assembly/final.contigs.fa")
    output:
        outdir = directory("{sample}/genomad/coassembly")
    params:
        db = config["genomad"]["db"],
        threads = config["genomad"]["threads"]
    conda: "../../envs/genomad_env.yml"
    benchmark: "{sample}/genomad/coassembly/benchmarks/{sample}.txt"
    log: "{sample}/genomad/coassembly/logs/{sample}.txt"
    group: "genomad"
    shell:
       """
       genomad end-to-end -t {params.threads} \
       --cleanup --restart {input.fasta} {output.outdir} {params.db}
       """
