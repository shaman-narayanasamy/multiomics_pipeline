all_coverm_inputs = [
    f"{catalogue}/alignments/{omics}/{sample}.{omics}.reads.sorted.bam"
    for sample, omics in valid_sample_omics
    for catalogue in catalogues
]

#rule coverm_contigs:
#    input:
#       bams = all_coverm_inputs,
#       fasta = "{catalogue}/indexes/sequences.fa",
#    output:
#       output_tsv = "{catalogue}/coverage/{omics}/coverm/output.tsv/output.tsv"
#    threads: 24
#    conda: 
#       "coverm_env"
#    benchmark: "{catalogue}/coverage/{omics}/benchmarks/coverm.txt"
#    log: "{catalogue}/coverage/{omics}/log/coverm.log"
#    shell:
#       """
#       mkdir -p {output.out_dir}
# 
#       coverm contig -b {input.bams} \
#       -m mean trimmed_mean count reads_per_base rpkm tpm covered_fraction covered_bases length \
#       -o {output.out_dir}/output.tsv -t {threads}
#       """

rule coverm_contigs:
    input:
        bams = lambda wildcards: [
            f"{wildcards.catalogue}/alignments/{wildcards.omics}/{sample}.{wildcards.omics}.reads.sorted.bam"
            for sample, otype in valid_sample_omics
            if otype == wildcards.omics
        ],
        fasta = "{catalogue}/indexes/sequences.fa",
    output:
        output_tsv = "{catalogue}/coverage/{omics}/coverm/output.tsv/output.tsv"
    threads: 24
    conda: "../../envs/coverm_env.yml"
    benchmark: "{catalogue}/coverage/{omics}/benchmarks/coverm.txt"
    log: "{catalogue}/coverage/{omics}/log/coverm.log"
    shell:
        """
        mkdir -p $(dirname {output.output_tsv})

        coverm contig -b {input.bams} \
        -m mean trimmed_mean count reads_per_base rpkm tpm covered_fraction covered_bases length \
        -o {output.output_tsv} -t {threads}
        """

metrics = [
    "Mean",
    "Trimmed Mean",
    "Read Count",
    "Reads per base",
    "RPKM",
    "TPM",
    "Covered Fraction",
    "Covered Bases"
]

metric_names = [m.replace(" ", "_") for m in metrics]

split_coverm_outputs = [
    f"{catalogue}/coverage/{omics}/coverm/output-{metric}.tsv"
    for catalogue in catalogues
    for sample, omics in valid_sample_omics
    for metric in metric_names
]

rule split_coverm_by_metric:
    input:
        coverm_output = lambda wildcards: f"{wildcards.catalogue}/coverage/{wildcards.omics}/coverm/output.tsv/output.tsv"
    output:
        temp("{catalogue}/coverage/{omics}/coverm/output-{metric}.tsv")
    threads: 1
    conda: "../../envs/csvtk_env.yml"
    shell:
        r"""
        metric=$(printf '%s' "{wildcards.metric}" | tr '_' ' ')
        cols=$(awk -v metric="$metric" 'BEGIN{{FS="\t"}} NR==1{{cols="1"; for(i=2;i<=NF;i++) if($i ~ (" " metric "$")) cols=cols "," i; print cols; exit}}' {input.coverm_output})
        if [[ "$cols" == "1" ]]; then
            echo "No CoverM columns matched metric '$metric' in {input.coverm_output}" >&2
            exit 2
        fi
        csvtk cut -t -f "$cols" {input.coverm_output} > {output}
        """
