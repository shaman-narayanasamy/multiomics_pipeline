## Semibin needs to have each fasta file with a unique name regardless of its location
rule soft_link_unique:
    input:
        fasta = "{sample}/all_prokaryotic_seqs.fa"
    output:
        fasta = '{sample}/{sample}.fa',
    shell:
        """ 
        ln -s all_prokaryotic_seqs.fa {output.fasta}
        """

rule semibin_multi_sample_concatenate_contigs:
    input:
        expand("{sample}/{sample}.fa", sample = samples.index)
    output:
        fasta = 'semibin_multi_sample/concatenated.fa',
    params:
        outdir = 'semibin_multi_sample'
    conda: "../../envs/semibin2_env.yml"
    benchmark: "semibin_multi_sample/benchmarks/semibin2_multi_sample.txt"
    log: "semibin_multi_sample/logs/semibin2_multi_sample.txt"
    shell:
        """ 
        SemiBin2 concatenate_fasta -i {input} -o {params.outdir} \
        --compression none
        """

rule semibin_multi_sample_bwa_index_assembly:
    input:
        fasta = 'semibin_multi_sample/concatenated.fa'
    output:
        "semibin_multi_sample/concatenated.fa.amb",
        "semibin_multi_sample/concatenated.fa.bwt",
        "semibin_multi_sample/concatenated.fa.pac",
        "semibin_multi_sample/concatenated.fa.ann",
        "semibin_multi_sample/concatenated.fa.sa"
    resources:
        mem_mb = 100000
    threads: 6
    conda: "../../envs/bwa_env.yml"
    benchmark: "semibin_multi_sample/benchmarks/bwa_indexing.txt"
    log: "semibin_multi_sample/logs/bwa_indexing.log"
    shell:
        """
        bwa index {input.fasta}
        """

rule semibin_multi_sample_bwa_mg_mapping_on_assembly:
    input:
        r_1 = os.path.join(config["input_dir"]["mg_assembly_input"], "{sample}/{sample}_R1.processed.fastq.gz"),
        r_2 = os.path.join(config["input_dir"]["mg_assembly_input"], "{sample}/{sample}_R2.processed.fastq.gz"),
        r_se = os.path.join(config["input_dir"]["mg_assembly_input"], "{sample}/{sample}_SE.processed.fastq.gz"),
	assembly="semibin_multi_sample/concatenated.fa",
        assembly_amb="semibin_multi_sample/concatenated.fa.amb",
        assembly_bwt="semibin_multi_sample/concatenated.fa.bwt",
        assembly_pac="semibin_multi_sample/concatenated.fa.pac",
        assembly_ann="semibin_multi_sample/concatenated.fa.ann",
        assembly_sa="semibin_multi_sample/concatenated.fa.sa"
    output:
        'semibin_multi_sample/{sample}_metaG.reads.sorted.bam'
    params: 
        prefix = "semibin_multi_sample/{sample}_metaG.reads",
        memory = 250
    resources:
        memory = 250
    threads: 24 
    group: "bwa_mapping_on_assembly"
    conda: "../../envs/bwa_env.yml"
    benchmark: "semibin_multi_sample/benchmarks/{sample}_bwa_mapping.txt"
    log: "semibin_multi_sample/logs/{sample}_bwa_mapping.log"
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

rule sembibin_multi_sample_index_mg_bam:
    input:
        'semibin_multi_sample/{sample}_metaG.reads.sorted.bam'
    output:
        'semibin_multi_sample/{sample}_metaG.reads.sorted.bam.bai'
    conda: "../../envs/bwa_env.yml"
    group: "bwa_index_assembly"
    benchmark: "semibin_multi_sample/benchmarks/{sample}_index_bam.txt"
    log: "semibin_multi_sample/logs/{sample}_index_bam.txt"
    shell:
        """
        samtools index {input} > {log} 2>&1
        """

rule semibin_multi_sample:
    input:
        bams = expand('semibin_multi_sample/{sample}_metaG.reads.sorted.bam', sample = samples.index),
        fasta = 'semibin_multi_sample/concatenated.fa'
    output:
        done = 'semibin_multi_sample/binning.done',
        outdir = directory('semibin_multi_sample/output')
    params:
        tmpdir = config["tmp_dir"],
        threads = config["semibin_multi_sample"]["threads"],
        min_contig_length = config["binning"]["min_contig_length"],
    conda: "../../envs/semibin2_env.yml"
    benchmark: "semibin_multi_sample/benchmarks/semibin2.txt"
    log: "semibin_multi_sample/logs/semibin2.txt"
    shell:
       """
       mkdir -p {output.outdir}
       
       SemiBin2 multi_easy_bin \
       --tmpdir {params.tmpdir} \
       --engine auto \
       -m {params.min_contig_length} \
       -i {input.fasta} \
       -b semibin_multi_sample/*.bam \
       -o {output.outdir} \
       -t {params.threads}

       touch {output.done}
       """

rule semibin_multi_sample_contig_to_bin:
    input:
        fasta = "{sample}/all_prokaryotic_seqs.fa",
        bin_dir = 'semibin_multi_sample/output'
    output:
        contig_to_bin="semibin_multi_sample/{sample}_contig_to_bin.tsv"
    shell:
        """
        for file in {input.bin_dir}/bins/*; do
          if [[ $file == *.fa.gz ]]; then
            echo "Decompressing $file"
            gunzip "$file"
          else
            echo "Skipping $file, already decompressed"
          fi
        done

        #gunzip {input.bin_dir}/bins/{wildcards.sample}_SemiBin_*.fa.gz
        
        ls {input.bin_dir}/bins/{wildcards.sample}_SemiBin_*.fa | \
        xargs -I{{}} bash -c 'paste <(yes "{{}}" | \
        head -n $(grep -c "^>" {{}}) | \
        sed -e "s:{input.bin_dir}/bins/::g") \
        <(grep "^>" {{}} | \
        sed -e "s/>//g") <(yes "semibin_multi_sample" | \
        head -n $(grep -c "^>" {{}}))' | \
        sed -e 's/\.fa//g' > {output.contig_to_bin}
        """
