rule prepare_catbat_bins:
    input:
        bin_fastas = lambda wildcards: genomes
    output:
        donefile = "catbat/input_bins.done"
    params:
        outdir = "catbat/input_bins"
    shell:
        """
        rm -rf {params.outdir}
        mkdir -p {params.outdir}

        for fasta in {input.bin_fastas}; do
            base=$(basename "$fasta" .fasta)
            sed -e 's/> />/g' "$fasta" > "{params.outdir}/${{base}}.fasta"
        done

        touch {output.donefile}
        """

rule catbat_classification:
    input:
        donefile = "catbat/input_bins.done"
    output:
        donefile = "catbat/{db_name}/catbat.done",
        bin_classification = "catbat/{db_name}/BAT.bin2classification.txt"
    params: 
        db_path=lambda wildcards: config['catbat']['db_path'][wildcards.db_name],
        tx_path=lambda wildcards: config['catbat']['tx_path'][wildcards.db_name],
        bin_folder = "catbat/input_bins",
        cat_command = config.get('catbat', {}).get('command', 'CAT_pack')
    threads: config["catbat"]["threads"]
    conda: 
        "../../envs/catbat_env.yml"
    container:
        "/ibex/user/naras0c/singularity/catbat/catbat.simg"
    shadow: "shallow"
    benchmark: "catbat/benchmarks/{db_name}_catbat_annotation.txt"
    log: "catbat/logs/{db_name}_catbat_annotation.txt"
    shell: 
        """ 
        mkdir -p catbat/{wildcards.db_name}

        {params.cat_command} bins --force \
        -b {params.bin_folder} \
        -d {params.db_path} \
        -t {params.tx_path} \
        -n {threads} \
        -s fasta \
        -o catbat/{wildcards.db_name}/BAT

        touch {output.donefile}
	"""

rule catbat_summary:
    input:
        donefile = "catbat/{db_name}/catbat.done",
        bin_classification = "catbat/{db_name}/BAT.bin2classification.txt"
    output:
        bin_classification_names_added = "catbat/{db_name}/BAT.bin2classification.names_added.txt",
        donefile = "catbat/{db_name}/catbat_summary.done"
    params: 
        db_path=lambda wildcards: config['catbat']['db_path'][wildcards.db_name],
        tx_path=lambda wildcards: config['catbat']['tx_path'][wildcards.db_name],
        cat_command = config.get('catbat', {}).get('command', 'CAT_pack')
    conda: 
        "../../envs/catbat_env.yml"
    container:
        "/ibex/user/naras0c/singularity/catbat/catbat.simg"
    benchmark: "catbat/benchmarks/{db_name}_catbat_summary.txt"
    log: "catbat/logs/{db_name}_catbat_summary.txt"
    shell: 
        """        
        {params.cat_command} add_names -i {input.bin_classification} -o {output.bin_classification_names_added} -t {params.tx_path} --only_official

        touch {output.donefile}
        """
