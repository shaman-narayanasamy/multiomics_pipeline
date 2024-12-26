rule deepmicroclass_predict:
    input:
        fasta=lambda wildcards: samples.at[(wildcards.sample), "fasta"]
    output:
        predictions = "{sample}/DeepMicroClass/{input.fasta}_pred_one-hot_hybrid.tsv"
    container: "/home/naras0c/repositories/github/DeepMicroClass/DeepMicroClass.sif"
    shadow: "shallow"
    benchmark: os.path.join("{sample}/benchmarks/deepmicroclass_predict.txt")
    log: os.path.join("{sample}/logs/deepmicroclass_predict.log")
    shell:
        """
        DeepMicroClass predict -i {input.fasta} -o {wildcards.sample}/DeepMicroClass
        """

rule deepmicroclass_extract:
    input:
        fasta=lambda wildcards: samples.at[(wildcards.sample), "fasta"],
        #predictions = "{sample}/DeepMicroClass/{sample}.coassembly_contigs.fa_pred_one-hot_hybrid.tsv"
        #predictions = "{sample}/DeepMicroClass/{input.fasta}_pred_one-hot_hybrid.tsv"
        #predictions=lambda wildcards, input: f"{wildcards.sample}/DeepMicroClass/{os.path.basename(input.fasta)}_pred_one-hot_hybrid.tsv"
        predictions=lambda wildcards: f"{wildcards.sample}/DeepMicroClass/{os.path.basename(samples.at[wildcards.sample, 'fasta'])}_pred_one-hot_hybrid.tsv"
    output:
        prokaryotes = "{sample}/DeepMicroClass/prokaryotes.fa",
        eukaryotes = "{sample}/DeepMicroClass/eukaryotes.fa",
        prokaryotic_viruses = "{sample}/DeepMicroClass/prokaryotic_viruses.fa",
        eukaryotic_viruses = "{sample}/DeepMicroClass/eukaryotic_viruses.fa",
        plasmids = "{sample}/DeepMicroClass/plasmids.fa"
    container: "/home/naras0c/repositories/github/DeepMicroClass/DeepMicroClass.sif"
    shadow: "shallow"
    benchmark: os.path.join("{sample}/benchmarks/deepmicroclass_extract.txt")
    log: os.path.join("{sample}/logs/deepmicroclass_extract.log")
    shell:
        """
        ## Extract prokaryote sequences
	DeepMicroClass extract --tsv {input.predictions} --fasta {input.fasta} \
        --class Prokaryote --output {output.prokaryotes}

        ## Extract eukaryote sequences
	DeepMicroClass extract --tsv {input.predictions} --fasta {input.fasta} \
        --class Eukaryote --output {output.eukaryotes}

        ## Extract eukaryotic virus sequences
	DeepMicroClass extract --tsv {input.predictions} --fasta {input.fasta} \
        --class EukaryoteVirus --output {output.eukaryotic_viruses}

        ## Extract prokaryotic viruses sequences
	DeepMicroClass extract --tsv {input.predictions} --fasta {input.fasta} \
        --class ProkaryoteVirus --output {output.prokaryotic_viruses}

        ## Extract plasmids sequences
	DeepMicroClass extract --tsv {input.predictions} --fasta {input.fasta} \
        --class Plasmid --output {output.plasmids}
       """

rule get_all_prokaryotic_seqs:
    input:
        prokaryotes = "{sample}/DeepMicroClass/prokaryotes.fa",
        prokaryotic_viruses = "{sample}/DeepMicroClass/prokaryotic_viruses.fa",
        plasmids = "{sample}/DeepMicroClass/plasmids.fa"
    output: "{sample}/all_prokaryotic_seqs.fa"
    benchmark: os.path.join("{sample}/benchmarks/get_all_prokaryotic_seqs.txt")
    log: os.path.join("{sample}/logs/get_all_prokaryotic_seqs.log")
    shell:
        """
        ## For binning, we are going to group together all prokaryotic-related sequences, including viruses 
        ## and plasmids for binning

        cat {input} > {output}
        """

rule bwa_index_assembly:
    input:
        fasta = "{sample}/all_prokaryotic_seqs.fa",
    output:
        "{sample}/all_prokaryotic_seqs.fa.amb",
        "{sample}/all_prokaryotic_seqs.fa.bwt",
        "{sample}/all_prokaryotic_seqs.fa.pac",
        "{sample}/all_prokaryotic_seqs.fa.ann",
        "{sample}/all_prokaryotic_seqs.fa.sa"
    resources:
        mem_gb = 100000
    threads: 6
    conda: "../../envs/bwa_env.yml"
    benchmark: "{sample}/benchmarks/bwa_indexing.txt"
    log: "{sample}/logs/bwa_indexing.log"
    shell:
        """
        bwa index {input.fasta}
        """

rule bwa_mg_mapping_on_assembly:
    input:
        r_1=lambda wildcards: samples.at[(wildcards.sample), "R1"],
        r_2=lambda wildcards: samples.at[(wildcards.sample), "R2"],
        r_se=lambda wildcards: samples.at[(wildcards.sample), "SE"],
	assembly="{sample}/all_prokaryotic_seqs.fa",
        assembly_amb="{sample}/all_prokaryotic_seqs.fa.amb",
        assembly_bwt="{sample}/all_prokaryotic_seqs.fa.bwt",
        assembly_pac="{sample}/all_prokaryotic_seqs.fa.pac",
        assembly_ann="{sample}/all_prokaryotic_seqs.fa.ann",
        assembly_sa="{sample}/all_prokaryotic_seqs.fa.sa"
    output:
        '{sample}/{sample}_metaG.reads.sorted.bam'
    params: 
        prefix = "{sample}/{sample}_metaG.reads",
        memory = 250
    resources:
        memory = 250
    threads: 24 
    group: "bwa_mapping_on_assembly"
    conda: "../../envs/bwa_env.yml"
    benchmark: "{sample}/benchmarks/bwa_mapping.txt"
    log: "{sample}/logs/bwa_mapping.log"
    shell:
        """
        SAMHEADER="@RG\\tID:{wildcards.sample}\\tSM:metaG"

        PREFIX={params.prefix}

        MEM_PER_CORE=$(({params.memory}/{threads}))

        # merge paired and se
        samtools merge --threads {threads} -f $PREFIX.merged.bam \
         <(bwa mem -v 1 -t {threads} -M -R \"$SAMHEADER\" {input.assembly} {input.r_1} {input.r_2} 2>> {log}| \
         samtools view --threads {threads} -bS -) \
         <(bwa mem -v 1 -t {threads} -M -R \"$SAMHEADER\" {input.assembly} {input.r_se} 2>> {log}| \
         samtools view --threads {threads} -bS -) 2>> {log}

        # sort
        samtools sort --threads {threads} -m ${{MEM_PER_CORE}}G $PREFIX.merged.bam > $PREFIX.sorted.bam 2>> {log}
        rm $PREFIX.merged.bam
        """

rule index_mg_bam:
    input:
        bam = '{sample}/{sample}_metaG.reads.sorted.bam'
    output:
        bai = '{sample}/{sample}_metaG.reads.sorted.bam.bai'
    conda: "../../envs/bwa_env.yml"
    group: "bwa_index_assembly"
    benchmark: "{sample}/benchmarks/index_bam.txt"
    log: "{sample}/logs/index_bam.txt"
    shell:
        """
        samtools index {input} > {log} 2>&1
        """
