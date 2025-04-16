process STACKS_DENOVO_MAP {
    tag "stacks_denovo_map"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/stacks:2.61--hd03093a_1' :
        'quay.io/biocontainers/stacks:2.61--hd03093a_1' }"

    input:
    val meta
    path reads, stageAs: "processed_reads/*"

    output:
    path "*.log.distribs", emit: distrib_logs
    path "populations.sumstats_summary.tsv", emit: sumstats_summary
    path "*.*", emit: denovo_outputs
    path "populations.snps.vcf", emit: vcf
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def p_string = ""
    meta.each {p_string += "${it.id}\t${it.pop}\n"}

    """
    printf "${p_string}" > popmap.txt
    denovo_map.pl --samples ./processed_reads/ \\
    --popmap popmap.txt \\
    -o . \\
    -m ${params.small_m} \\
    -M ${params.big_m} \\
    -n ${params.small_n} \\
    -T ${task.cpus} \\
    ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        stacks: \$(ustacks --help 2>&1 | sed '2,\$d; s/ustacks //g')
    END_VERSIONS
    """
}