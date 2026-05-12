rule prepare_custom_bakta_db:
    output:
        custom_db = temp("bakta/custom_proteins.fasta")
    params:
        custom_dbs = " ".join(config['bakta']['custom_dbs'].values()) if config['bakta']['custom_dbs'] else ""
    shell:
        """
        if [ ! -z "{params.custom_dbs}" ]; then
            cat {params.custom_dbs} > {output.custom_db}
        else
            touch {output.custom_db}  # Create an empty file to avoid errors
        fi
        """

rule bakta_annotation:
    wildcard_constraints:
        bin_id = "(?!custom_proteins\\.fasta$)[^/]+"
    input:
        bin_fasta = lambda wildcards: genome_index[wildcards.bin_id],
    output:
        donefile = "bakta/{bin_id}/bakta.done",
        out_dir = directory("bakta/{bin_id}")
    params: 
        db_path=config['bakta']['db_path'],
        custom_db = "bakta/custom_proteins.fasta"
    threads: 12
    conda: 
        "../../envs/bakta_env.yml"
    container:
        "docker://oschwengers/bakta:latest"
    benchmark: "bakta/{bin_id}/benchmarks/bakta_annotation.txt"
    log: "bakta/{bin_id}/logs/bakta_annotation.txt"
    shell: 
        """ 
        PROTEIN_ARG=""
        if [ -s {params.custom_db} ]; then
            PROTEIN_ARG="--proteins {params.custom_db}"
        fi

        bakta {input.bin_fasta} --force --db {params.db_path} $PROTEIN_ARG \
        --output {output.out_dir}/ --prefix {wildcards.bin_id} -t {threads} \
        --keep-contig-headers --skip-plot
        touch {output.donefile}
        """
