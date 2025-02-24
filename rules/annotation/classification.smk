rule catbat_classification:
    input:
        bin_folder = config["genomes_dir"]
    output:
        donefile = "catbat/{db_name}/catbat.done",
        bin_classification = "catbat/{db_name}/BAT.bin2classification.txt"
    params: 
        db_path=lambda wildcards: config['catbat']['db_path'][wildcards.db_name],
        tx_path=lambda wildcards: config['catbat']['tx_path'][wildcards.db_name]
    threads: 40
    conda: 
        "../../../envs/catbat_env.yml"
    container:
        "/ibex/user/naras0c/singularity/catbat/catbat.simg"
    shadow: "shallow"
    benchmark: "catbat/benchmarks/{db_name}_catbat_annotation.txt"
    log: "catbat/logs/{db_name}_catbat_annotation.txt"
    shell: 
        """ 
        # Create temporary directory for "corrected" fasta files (required by CAT/BAT)
        mkdir -p {input.bin_folder}/fixed_fasta
        
        # Generate new fasta files without spaces in the header
        for fasta in {input.bin_folder}/*.fasta; do
            base=$(basename "$fasta" .fasta)
            cat "$fasta" | sed -e 's/> />/g' > "{input.bin_folder}/fixed_fasta/${{base}}.fasta"
        done
        
        # Run program on new folder with corrected fasta files
        mkdir -p catbat
	CAT bins --force -b {input.bin_folder}/fixed_fasta -d {params.db_path} -t {params.tx_path} -n {threads} -s fasta -o catbat/{wildcards.db_name}/BAT

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
        catpack_script=config['catbat']['catpack_script']
    conda: 
        "../../../envs/catbat_env.yml"
    container:
        "/ibex/user/naras0c/singularity/catbat/catbat.simg"
    benchmark: "catbat/benchmarks/{db_name}_catbat_summary.txt"
    log: "catbat/logs/{db_name}_catbat_summary.txt"
    shell: 
        """        
        db_name="{wildcards.db_name}"

        if [[ $db_name == "gtdb" ]]; then

        touch {output.bin_classification_names_added} 

        else

        {params.catpack_script} add_names -i {input.bin_classification} -o {output.bin_classification_names_added} -t {params.tx_path} --only_official

        fi 

        touch {output.donefile}
        """
