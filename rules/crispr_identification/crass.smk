rule crass_reads_metagenomics:
    input:
        filtered_mg_paired_read_1=lambda wildcards: os.path.join(
            config["output_dir"], f"metagenomics/preprocessing/{wildcards.sample}/{wildcards.sample}_R1.processed.fastq.gz"
        ),
        filtered_mg_paired_read_2=lambda wildcards: os.path.join(
            config["output_dir"], f"metagenomics/preprocessing/{wildcards.sample}/{wildcards.sample}_R2.processed.fastq.gz"
        ),
        filtered_mg_unpaired_read=lambda wildcards: os.path.join(
            config["output_dir"], f"metagenomics/preprocessing/{wildcards.sample}/{wildcards.sample}_SE.processed.fastq.gz"
        ),
    output:
        outfile="{sample}/crass_reads_out/metagenomics/crass.crispr",
        spacers="{sample}/crass_reads_out/metagenomics/spacers.fa",
        repeats="{sample}/crass_reads_out/metagenomics/repeats.fa",
        flanks="{sample}/crass_reads_out/metagenomics/flanks.fa",
    params:
        threads = 12
    group: "crass"
    log: "{sample}/logs/metagenomics_crass_reads.txt",
    conda: "../../envs/crass_env.yml",
    shell:
        """
        crass -o {wildcards.sample}/crass_reads_out/metagenomics \
        {input.filtered_mg_paired_read_1} {input.filtered_mg_paired_read_2} {input.filtered_mg_unpaired_read}

        crisprtools extract -H {wildcards.sample}:metagenomics: \
        -o {wildcards.sample}/crass_reads_out/metagenomics \
        -sspacers.fa -drepeats.fa -fflanks.fa {output.outfile}

        dir="{wildcards.sample}/crass_reads_out/metagenomics/"
        
        mv $dir/{wildcards.sample}:metagenomics:spacers.fa $dir/spacers.fa
        mv $dir/{wildcards.sample}:metagenomics:repeats.fa $dir/repeats.fa
        mv $dir/{wildcards.sample}:metagenomics:flanks.fa $dir/flanks.fa
        """

       # -O {wildcards.sample}_metagenomics_ \

rule crass_reads_metatranscriptomics:
    input:
        filtered_mt_paired_read_1=lambda wildcards: os.path.join(
            config["output_dir"], f"metatranscriptomics/preprocessing/{wildcards.sample}/{wildcards.sample}_R1.processed.fastq.gz"
        ),
        filtered_mt_paired_read_2=lambda wildcards: os.path.join(
            config["output_dir"], f"metatranscriptomics/preprocessing/{wildcards.sample}/{wildcards.sample}_R2.processed.fastq.gz"
        ),
        filtered_mt_unpaired_read=lambda wildcards: os.path.join(
            config["output_dir"], f"metatranscriptomics/preprocessing/{wildcards.sample}/{wildcards.sample}_SE.processed.fastq.gz"
        ),
    output:
        outfile="{sample}/crass_reads_out/metatranscriptomics/crass.crispr",
        spacers="{sample}/crass_reads_out/metatranscriptomics/spacers.fa",
        repeats="{sample}/crass_reads_out/metatranscriptomics/repeats.fa",
        flanks="{sample}/crass_reads_out/metatranscriptomics/flanks.fa",
    params:
        threads = 12
    group: "crass"
    log: "{sample}/logs/metatranscriptomics_crass_reads.txt",
    conda: "../../envs/crass_env.yml",
    shell:
        """
        crass -o {wildcards.sample}/crass_reads_out/metatranscriptomics \
        {input.filtered_mt_paired_read_1} {input.filtered_mt_paired_read_2} {input.filtered_mt_unpaired_read}

        crisprtools extract -H {wildcards.sample}:metatranscriptomics: \
        -o {wildcards.sample}/crass_reads_out/metatranscriptomics \
        -sspacers.fa -drepeats.fa -fflanks.fa {output.outfile}

        dir="{wildcards.sample}/crass_reads_out/metatranscriptomics/"
        
        mv $dir/{wildcards.sample}:metatranscriptomics:spacers.fa $dir/spacers.fa
        mv $dir/{wildcards.sample}:metatranscriptomics:repeats.fa $dir/repeats.fa
        mv $dir/{wildcards.sample}:metatranscriptomics:flanks.fa $dir/flanks.fa
        """

        #-O {wildcards.sample}_metatranscriptomics_ \

def get_assembly_path(wildcards):
    """Determine the correct assembly path based on the omics availability."""
    sample = wildcards.sample
    omics_type = samples.loc[samples["sample_alias"] == sample, "omics"].values[0]
    
    if omics_type == "both":
        # Coassembly path for samples with both metagenomics and metatranscriptomics
        return f"/ibex/project/e3018/airport_surveillance/output/coassembly/{sample}/{sample}.coassembly_contigs.fa"
    elif omics_type == "metagenomics":
        # Metagenomics-only path
        return f"/ibex/project/e3018/airport_surveillance/output/metagenomics/assembly/{sample}/{sample}.assembly_contigs.fa"
    elif omics_type == "metatranscriptomics":
        # Metatranscriptomics-only path
        return f"/ibex/project/e3018/airport_surveillance/output/metatranscriptomics/assembly/{sample}/megahit_assembly/final.contigs.fa"
    else:
        raise ValueError(f"Unexpected omics type '{omics_type}' for sample '{sample}'")

rule crass_contigs:    
    input:
        assembly = get_assembly_path
    output:
        outfile = "{sample}/crass_contigs_out/crass.crispr",
        spacers = "{sample}/crass_contigs_out/spacers.fa",
        repeats = "{sample}/crass_contigs_out/repeats.fa",
        flanks = "{sample}/crass_contigs_out/flanks.fa"
    params:
        threads = 12
    group: "crass"
    conda: "../../envs/crass_env.yml"
    benchmark: "{sample}/benchmarks/crass_contigs.txt"
    log: "{sample}/logs/crass_contigs.txt"
    shell:
        """
        crass -o {wildcards.sample}/crass_contigs_out {input}

        crisprtools extract -H {wildcards.sample}:contigs: \
        -o {wildcards.sample}/crass_contigs_out \
        -sspacers.fa -drepeats.fa -fflanks.fa {output.outfile}  

        dir="{wildcards.sample}/crass_contigs_out"
        
        mv $dir/{wildcards.sample}:contigs:spacers.fa $dir/spacers.fa
        mv $dir/{wildcards.sample}:contigs:repeats.fa $dir/repeats.fa
        mv $dir/{wildcards.sample}:contigs:flanks.fa $dir/flanks.fa
        """
        #-O {wildcards.sample}_contigs_ \

def get_available_omics(sample):
    """Returns a list of available omics for a given sample."""
    return omics_mapping.get(sample, [])

rule cluster_crispr_spacers:
    input:
        lambda wildcards: [
            f"{sample}/crass_reads_out/{omics}/spacers.fa"
            for sample, omics_list in omics_mapping.items()
            for omics in omics_list
        ] + [
            f"{sample}/crass_contigs_out/spacers.fa"
            for sample in omics_mapping.keys()
        ]
    output:
        "spacers_cluster.tsv",
        "spacers_rep_seq.fasta",
        "spacers_all_seqs.fasta"
    params: 
        threads = 24
    group: "mmseqs2"
    conda: "mmseqs2_env"
    benchmark: "benchmarks/crass_cluster_spacers.txt"
    log: "logs/crass_cluster_spacers.log"
    shell:
        """
        if [[ -z "{input}" ]]; then
            echo "No valid input files for clustering spacers" >&2
            exit 1
        fi 

        cat {input} > {tmp_dir}/spacers_concatenated_tmp.fa

        mmseqs easy-cluster {tmp_dir}/spacers_concatenated_tmp.fa spacers tmp \
        --min-seq-id 0.9 \
        --cov-mode 0 -c 0.95 \
        --alignment-mode 3 \
        --threads {params.threads} \
        -k 5
        """

rule cluster_crispr_repeats:
    input:
        lambda wildcards: [
            f"{sample}/crass_reads_out/{omics}/repeats.fa"
            for sample, omics_list in omics_mapping.items()
            for omics in omics_list
        ] + [
            f"{sample}/crass_contigs_out/repeats.fa"
            for sample in omics_mapping.keys()
        ]
    output:
        "repeats_cluster.tsv",
        "repeats_rep_seq.fasta",
        "repeats_all_seqs.fasta"
    params: 
        threads = 24
    group: "mmseqs2"
    conda: "mmseqs2_env"
    benchmark: "benchmarks/crass_cluster_repeats.txt"
    log: "logs/crass_cluster_repeats.txt"
    shell:
        """

        if [[ -z "{input}" ]]; then
            echo "No valid input files for clustering repeats" >&2
            exit 1
        fi 

        cat {input} > {tmp_dir}/repeats_concatenated_tmp.fa

        mmseqs easy-cluster {tmp_dir}/repeats_concatenated_tmp.fa repeats tmp \
        --min-seq-id 0.8 \
        --cov-mode 0 -c 0.75 \
        --alignment-mode 3 \
        --threads {params.threads} \
        -k 7
        """

rule cluster_crispr_flanks:
    input:
        lambda wildcards: [
            f"{sample}/crass_reads_out/{omics}/flanks.fa"
            for sample, omics_list in omics_mapping.items()
            for omics in omics_list
        ] + [
            f"{sample}/crass_contigs_out/flanks.fa"
            for sample in omics_mapping.keys()
        ]
    output:
        "flanks_cluster.tsv",
        "flanks_rep_seq.fasta",
        "flanks_all_seqs.fasta"
    params: 
        threads = 24
    group: "mmseqs2"
    conda: "mmseqs2_env"
    benchmark: "benchmarks/crass_cluster_flanks.txt"
    log: "logs/crass_cluster_flanks.txt"
    shell:
        """

        if [[ -z "{input}" ]]; then
            echo "No valid input files for clustering flanking sequences" >&2
            exit 1
        fi

        cat {input} > {tmp_dir}/flanks_concatenated_tmp.fa

        mmseqs easy-cluster {tmp_dir}/flanks_concatenated_tmp.fa flanks tmp \
        --min-seq-id 0.99 \
        --cov-mode 0 -c 0.975 \
        --alignment-mode 3 \
        --threads {params.threads}
        """
