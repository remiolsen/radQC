process STACKS_DENOVO_MAP {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/stacks:2.61--hd03093a_1' :
        'quay.io/biocontainers/stacks:2.61--hd03093a_1' }"

    input:
    val meta
    path samples, stageAs: "processed_reads/*"

    output:
    tuple val(meta), path("*.log.distribs"), emit: distrib_logs
    tuple val(meta), path("populations.sumstats_summary.tsv"), emit: sumstats_summary
    tuple val(meta), path("*.*"), emit: denovo_outputs
    tuple val(meta), path("populations.snps.vcf"), emit: vcf
    path "versions.yml", emit: versions

    script:
    def outputs = "--vcf "
    outputs += params.genepop ? "--genepop ":""
    outputs += params.structure ? "--structure ":""
    outputs += params.plink ? "--plink ":""
    outputs += params.phylip ? "--phylip ":""
    outputs += params.radpainter ? "--radpainter ":""
    outputs += params.fasta_out ? "--fasta-loci --fasta-samples ":""

    def usamples = []
    samples.each {usamples += ["${it.simpleName}\tradseqQC\n"]}
    usamples = usamples.unique()
    def p_string = ""
    usamples.each {p_string += "${it}"}

    """
    printf "${p_string}" > popmap.txt
    denovo_map.pl --samples ./processed_reads/ \\
    --popmap popmap.txt \\
    -o . \\
    -m ${params.small_m} \\
    -M ${params.big_m} \\
    -n ${params.small_n} \\
    -T ${task.cpus} \\
    -X "populations: ${outputs}"
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        stacks: \$(ustacks --help 2>&1 | sed '2,\$d; s/ustacks //g')
    END_VERSIONS
    """
}