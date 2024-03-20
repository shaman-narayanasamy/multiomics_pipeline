rule split_fasta:
    input:
        multi_fasta  = os.path.join(phage_dirs, "{sample}/virsorter2/coassembly/final-viral-combined.fa") 
    output:
        output_dir = directory("{sample}/phage_database"),
    conda: "../../envs/seqkit_env.yml"
    params:
        threads = config["seqkit"]["threads"]
    shell:
        """
        if [ -d {input.multi_fasta} ]; then
            echo "{input.multi_fasta} is already a folder likely with multiple fasta files."
            echo "Creating soft link for {output.output_dir}"
            ln -s $(realpath {input.multi_fasta}) $(realpath {output.output_dir})
            touch {output.output_dir}
        else
            seqkit -j {params.threads} split --by-id {input.multi_fasta} \
            --extension .gz \
            -O {output.output_dir}
        fi
        """

rule create_spacepharer_db:
    input:
        split_fasta_dir = "{sample}/phage_database"
    output:
        output_dir  = directory("{sample}/spacepharer_db"),
        touch  = "{sample}/spacepharer_db.done"
    conda: "../../envs/spacepharer_env.yml"
    benchmark: "{sample}/spacepharer_db/benchmarks/{sample}_create_spacepharer_db.txt"
    log: "{sample}/spacepharer_db/logs/{sample}_create_spacepharer_db.log"
    shell:
        """
        mkdir -p {output.output_dir}
        mkdir -p {tmp_dir}/{wildcards.sample}/tmpFolder
        mkdir -p {tmp_dir}/{wildcards.sample}/tmpFolder_rev

        spacepharer createsetdb {wildcards.sample}/phage_database/*.gz \
        {output.output_dir}/targetSetDb {tmp_dir}/{wildcards.sample}/tmpFolder

        spacepharer createsetdb {wildcards.sample}/phage_database/*.gz \
        {output.output_dir}/targetSetDb_rev {tmp_dir}/{wildcards.sample}/tmpFolder_rev --reverse-fragments 1
        
        touch {output.touch}
        """

rule spacepharer:
    input:
        touch  = "{sample}/spacepharer_db.done",
        spacers = "{sample}/spacers.fa",
        phage_db_dir  = "{sample}/spacepharer_db"
    output:
        predictions = "{sample}/spacepharer/predictions.tsv"
    conda: "../../envs/spacepharer_env.yml"
    benchmark: "{sample}/spacepharer/benchmarks/spacepharer.txt"
    log: "{sample}/spacepharer/logs/spacepharer.txt"
    shell:
        """ 
        mkdir -p {wildcards.sample}/spacepharer

        # Need an if statement to ensure that the CRISPR files are not empty
        if [ -s {input.spacers} ]; then

            mkdir -p {tmp_dir}/tmpFolder/{wildcards.sample}
    
    	    spacepharer easy-predict {input.spacers} \
            {input.phage_db_dir}/targetSetDb {output} \
            {tmp_dir}/{wildcards.sample}/tmpFolder
        else
            touch {output}
        fi
        """ 
