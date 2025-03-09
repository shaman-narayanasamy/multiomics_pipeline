rule prepare_custom_bakta_db:
    output:
        custom_db = temp("bakta/custom_proteins.fasta")
    params:
#        custom_dbs = " ".join(config['bakta']['custom_dbs'].values()) if config['bakta']['custom_dbs'] else None
        custom_dbs = " ".join(config['bakta'].get('custom_dbs', {}).values()) if 'custom_dbs' in config['bakta'] else None
    shell:
        """
        if [ ! -z "{params.custom_dbs}" ]; then
            cat {params.custom_dbs} > {output.custom_db}
        else
            touch {output.custom_db}  # Create an empty file to avoid errors
        fi
        """

rule bakta_annotation:
    input:
        bin_fasta = lambda wildcards: genome_index[wildcards.bin_id],
        custom_db = "bakta/custom_proteins.fasta"
    output:
        donefile = "bakta/{bin_id}/bakta.done",
        out_dir = directory("bakta/{bin_id}")
    params: 
        db_path=config['bakta']['db_path']
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
        if [ -s {input.custom_db} ]; then
            PROTEIN_ARG="--proteins {input.custom_db}"
        fi

        bakta {input.bin_fasta} --force --db {params.db_path} $PROTEIN_ARG \
        --output {output.out_dir}/ --prefix {wildcards.bin_id} -t {threads} \
        --keep-contig-headers
        touch {output.donefile}
        """
