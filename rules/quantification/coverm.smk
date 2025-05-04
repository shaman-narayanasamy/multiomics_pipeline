# Precompute inputs
#all_coverm_inputs = []
#
#for sample, otypes in omics_mapping.items():
#    for omics in otypes:
#        for catalogue in catalogues:
#            all_coverm_inputs.append(f"alignments/{catalogue}/{omics}/{sample}.{omics}.reads.sorted.bam")
#            all_coverm_inputs.append(f"alignments/{catalogue}/genes/{omics}/{sample}.{omics}.reads.sorted.bam")

#all_coverm_inputs = []
#
#for sample, otypes in omics_mapping.items():
#    for omics in otypes:
#        for catalogue in catalogues:
#            all_coverm_inputs.append(f"{catalogue}/alignments/{omics}/{sample}.{omics}.reads.sorted.bam")

all_coverm_inputs = [
    f"{catalogue}/alignments/{omics}/{sample}.{omics}.reads.sorted.bam"
    for sample, omics in valid_sample_omics
    for catalogue in catalogues
]

rule coverm_contigs:
    input:
       bams = all_coverm_inputs,
       fasta = "indexes/{catalogue}/sequences.fa",
    output:
       out_dir = directory("{catalogue}/coverage/{omics}/coverm"),
    threads: 24
    conda: 
       "coverm_env"
    benchmark: "{catalogue}/coverage/{omics}/benchmarks/coverm.txt"
    log: "{catalogue}/coverage/{omics}/log/coverm.log"
    shell:
       """
       mkdir -p {output.out_dir}
 
       coverm contig -b {input.bams} -r {input.fasta} \
       -m mean trimmed_mean count reads_per_base rpkm tpm covered_fraction covered_bases length \
       -o {output.out_dir}/output.tsv -t {threads}
       """

       #coverm contig -b {wildcards.catalogue}/alignments/{wildcards.omics}/*/*.bam \
       #coverm contig -b coverage/{wildcards.catalogue}/{wildcards.omics} -r {input.fasta} \
       


#rule coverm_genomes_mt:
#    input:
#        genomes = config["coverm"]["genomes_dir"], 
#
#        r1 = lambda wildcards: os.path.join(
#            config["output_dir"], f"metatranscriptomics/preprocessing/{wildcards.sample}/{wildcards.sample}_R1.processed.fastq.gz"
#        ),
#        r2 = lambda wildcards: os.path.join(
#            config["output_dir"], f"metatranscriptomics/preprocessing/{wildcards.sample}/{wildcards.sample}_R2.processed.fastq.gz"
#        ),
#        se = lambda wildcards: os.path.join(
#            config["output_dir"], f"metatranscriptomics/preprocessing/{wildcards.sample}/{wildcards.sample}_SE.processed.fastq.gz"
#        )
#    output:
#        out_dir = directory("{sample}/coverm/metatranscriptomics"),
#        bam_dir = directory("{sample}/bam_dir/metatranscriptomics")
#    threads: 24
#    conda: 
#        #"../../envs/coverm_env.yml"
#        "coverm_env"
#    benchmark: "benchmarks/coverm/{sample}.txt"
#    log: "log/coverm/{sample}.log"
#    shell:
#        """
#        mkdir -p {output.out_dir}
#        mkdir -p {output.bam_dir}
#         
#        coverm genome -1 {input.r1} -2 {input.r2} --single {input.se} \
#        -d {input.genomes} -x fasta \
#        --min-covered-fraction 0 \
#        -m relative_abundance mean trimmed_mean count reads_per_base rpkm tpm covered_fraction covered_bases length \
#        -o {output.out_dir}/output --bam-file-cache-directory {output.bam_dir}/bamfile \
#	--use-full-contig-names \
#        -t {threads}
#        """
