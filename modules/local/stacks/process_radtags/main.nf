process STACKS_PROCESS_RADTAGS {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/stacks:2.61--hd03093a_1' :
        'quay.io/biocontainers/stacks:2.61--hd03093a_1' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*process_radtags.log"), emit: radtag_log
    tuple val(meta), path("*.{1,2}.fq.gz"), emit: processed_reads
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = reads[0].simpleName
    def args = task.ext.args ?: ''
    def paired_end = reads instanceof List
    def read_param = paired_end ? "-1 ${reads[0]} -2 ${reads[1]}": "-f $reads"
    def mv_cmds = "mv *.fq.gz ${prefix}.1.fq.gz"
    if (paired_end) {
        mv_cmds = """
            mv *_1.rem.1.fq.gz ${prefix}.rem1.fq.gz
            mv *_2.rem.2.fq.gz ${prefix}.rem2.fq.gz
            mv *_1.1.fq.gz ${prefix}.1.fq.gz
            mv *_2.2.fq.gz ${prefix}.2.fq.gz
        """
    }
    """
    process_radtags \\
    ${read_param} \\
    -e ${params.enzyme} \\
    --threads ${task.cpus} \\
    ${args}

    ${mv_cmds}
    mv process_radtags.log ${prefix}.process_radtags.log
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        stacks: \$(ustacks --help 2>&1 | sed '2,\$d; s/ustacks //g')
    END_VERSIONS
    """
}