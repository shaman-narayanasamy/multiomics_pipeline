rule coverm:
    input:
        mg_bam = '{sample}/{sample}_metaG.reads.sorted.bam',
        mt_bam = '{sample}/{sample}_metaT.reads.sorted.bam'
    output:
        coverm_output = '{sample}/coverm/{sample}_coverage.out'
    params:
        threads = config["coverm"]["threads"]
    conda: "../../envs/coverm_env.yml"
    benchmark: "{sample}/benchmarks/coverm.txt"
    log: "{sample}/benchmarks/coverm.log"
    shell:
        """
        TMPDIR=config["tmp_dir"]

        coverm contig -b {input} \
        -m mean count covered_bases length -o {output.coverm_output} \
        --output-format sparse -t {params.threads}
        """
