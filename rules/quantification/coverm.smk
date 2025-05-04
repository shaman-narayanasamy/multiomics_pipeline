all_coverm_inputs = [
    f"{catalogue}/alignments/{omics}/{sample}.{omics}.reads.sorted.bam"
    for sample, omics in valid_sample_omics
    for catalogue in catalogues
]

rule coverm_contigs:
    input:
       bams = all_coverm_inputs,
       fasta = "{catalogue}/indexes/sequences.fa",
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
 
       coverm contig -b {input.bams} \
       -m mean trimmed_mean count reads_per_base rpkm tpm covered_fraction covered_bases length \
       -o {output.out_dir}/output.tsv -t {threads}
       """
