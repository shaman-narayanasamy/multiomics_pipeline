rule catbat_classification:
    input:
        assembly="{sample}/{sample}.coassembly_contigs.fa",
    output:
        donefile = "{sample}/catbat/{db_name}/catbat.done",
        contig_classification = "{sample}/catbat/{db_name}/CAT.contig2classification.txt"
    params: 
        db_path=lambda wildcards: config['catbat']['db_path'][wildcards.db_name],
        tx_path=lambda wildcards: config['catbat']['tx_path'][wildcards.db_name]
    threads: 24
    conda: 
        "../../../envs/catbat_env.yml"
    container:
        "https://depot.galaxyproject.org/singularity/cat:5.2.3--hdfd78af_1"
    shadow: "shallow"
    benchmark: "{sample}/catbat/benchmarks/{db_name}_catbat_annotation.txt"
    log: "{sample}/catbat/logs/{db_name}_catbat_annotation.txt"
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
	CAT contigs -c {input.assembly} -d {params.db_path} -t {params.tx_path} -n {threads} -o catbat/{wildcards.db_name}/CAT

        touch {output.donefile}
	"""

rule catbat_summary:
    input:
        donefile = "{sample}/catbat/{db_name}/catbat.done",
        contig_classification = "{sample}/catbat/{db_name}/CAT.contig2classification.txt"
    output:
        contig_classification_names_added = "{sample}/catbat/{db_name}/CAT.contig2classification.names_added.txt",
        donefile = "{sample}/catbat/{db_name}/catbat_summary.done"
    params: 
        db_path=lambda wildcards: config['catbat']['db_path'][wildcards.db_name],
        tx_path=lambda wildcards: config['catbat']['tx_path'][wildcards.db_name]
    conda: 
        "../../../envs/catbat_env.yml"
    container:
        "https://depot.galaxyproject.org/singularity/cat:5.2.3--hdfd78af_1"
    benchmark: "{sample}/catbat/benchmarks/{db_name}_catbat_summary.txt"
    log: "{sample}/catbat/logs/{db_name}_catbat_summary.txt"
    shell: 
        """        
        CAT add_names -i {input.contig_classification} -o {output.contig_classification_names_added} -t {params.tx_path} --only_official

        touch {output.donefile}
        """
