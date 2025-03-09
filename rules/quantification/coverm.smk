# Precompute inputs
#all_coverm_inputs = []
#
#for sample, otypes in omics_mapping.items():
#    for omics in otypes:
#        for catalogue in catalogues:
#            all_coverm_inputs.append(f"alignments/{catalogue}/{omics}/{sample}.{omics}.reads.sorted.bam")
#            all_coverm_inputs.append(f"alignments/{catalogue}/genes/{omics}/{sample}.{omics}.reads.sorted.bam")

all_coverm_inputs = []

for sample, otypes in omics_mapping.items():
    for omics in otypes:
        for catalogue in catalogues:
            all_coverm_inputs.append(f"alignments/{catalogue}/{omics}/{sample}.{omics}.reads.sorted.bam")

            # Only add gene-level BAM if the catalogue has a BED file
            if "bed" in config["quantification"]["catalogues"][catalogue]:
                all_coverm_inputs.append(f"alignments/{catalogue}/{omics}/{sample}.{omics}.genes.reads.sorted.bam")

rule coverm:
    input:
       all_coverm_inputs,
       fasta = "{catalogue}/sequences.fa",
    output:
       out_dir = directory("coverage/{catalogue}/{omics}/coverm"),
    threads: 24
    conda: 
       "coverm_env"
    benchmark: "coverage/{catalogue}/{omics}/benchmarks/coverm.txt"
    log: "coverage/{catalogue}/{omics}/log/coverm.log"
    shell:
       """
       mkdir -p {output.out_dir}
 
       coverm contig -b coverage/{wildcards.catalogue}/{wildcards.omics} -r {input.fasta} \
       -m relative_abundance mean trimmed_mean count reads_per_base rpkm tpm covered_fraction covered_bases length \
       -o {output.out_dir}/output --use-full-contig-names -t {threads}
       """

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
