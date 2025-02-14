process STACKS_DENOVO_MAP {

    label 'process_high'

    conda     (params.enable_conda ? "bioconda::stacks=2.61" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/stacks:2.61--hd03093a_1' :
        'quay.io/biocontainers/stacks:2.61--hd03093a_1' }"

    input:
    path(samples)

    output:
    path "{populations.sumstats_summary.tsv,*.log.distribs}", emit: denovo_logs
    path "*.*", emit: denovo_outputs
    path "versions.yml", emit: versions

    script:
    def outputs = params.genepop ? "--genepop ":""
    outputs += params.structure ? "--structure ":""
    outputs += params.plink ? "--plink ":""
    outputs += params.phylip ? "--phylip ":""
    outputs += params.vcf ? "--vcf ":""
    outputs += params.radpainter ? "--radpainter ":""
    outputs += params.fasta_out ? "--fasta-loci --fasta-samples ":""

    def usamples = []
    samples.each {usamples += ["${it.simpleName}\tnfcore_radseq\n"]}
    usamples = usamples.unique()
    def p_string = ""
    usamples.each {p_string += "${it}"}

    """
    printf "${p_string}" > popmap.txt
    denovo_map.pl --samples . \\
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