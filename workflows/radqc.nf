/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { CAT_FASTQ                   } from '../modules/nf-core/cat/fastq/main'   
include { FASTQC                      } from '../modules/nf-core/fastqc/main'
include { MULTIQC                     } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { samplesheetToList } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_radqc_pipeline'
include { TRIMMOMATIC                 } from '../modules/nf-core/trimmomatic/main'
include { STACKS_PROCESS_RADTAGS      } from '../modules/local/stacks/process_radtags/main'
include { STACKS_DENOVO_MAP           } from '../modules/local/stacks/denovo_map/main'
include { VCFTOOLS_MANY               } from '../subworkflows/local/vcftools_many'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow RADQC {

    take:
    samplesheet // channel: samplesheet read in from --input
    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    ch_samplesheet = samplesheet
                        .branch { meta, fastqs ->
                            single  : fastqs.size() == 1
                                return [ meta, fastqs.flatten() ]
                            multiple: fastqs.size() > 1
                                return [ meta, fastqs.flatten() ]
                        }

    CAT_FASTQ (
        ch_samplesheet.multiple
    )
    ch_fastq = CAT_FASTQ.out.reads.mix(ch_samplesheet.single)

    TRIMMOMATIC (
        ch_fastq
    ) 

    FASTQC (
        TRIMMOMATIC.out.trimmed_reads
    )

    STACKS_PROCESS_RADTAGS (
        TRIMMOMATIC.out.trimmed_reads
    )

    STACKS_DENOVO_MAP (
        STACKS_PROCESS_RADTAGS.out.processed_reads.collect{it[0]},
        STACKS_PROCESS_RADTAGS.out.processed_reads.collect{it[1]}
    )


    ch_denovo_vcf = STACKS_DENOVO_MAP.out.vcf.map { it -> [[id: "stacks_denovo_map"], it] }

    VCFTOOLS_MANY (
        ch_denovo_vcf
    )

    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]})
    ch_multiqc_files = ch_multiqc_files.mix(TRIMMOMATIC.out.out_log.collect{it[1]})
    ch_multiqc_files = ch_multiqc_files.mix(STACKS_PROCESS_RADTAGS.out.radtag_log.collect{it[1]})
    ch_multiqc_files = ch_multiqc_files.mix(STACKS_DENOVO_MAP.out.distrib_logs)
    ch_multiqc_files = ch_multiqc_files.mix(STACKS_DENOVO_MAP.out.sumstats_summary)
    ch_multiqc_files = ch_multiqc_files.mix(VCFTOOLS_MANY.out.vcftools_relatedness2.collect{it[1]})
    ch_multiqc_files = ch_multiqc_files.mix(VCFTOOLS_MANY.out.vcftools_het.collect{it[1]})
    ch_multiqc_files = ch_multiqc_files.mix(VCFTOOLS_MANY.out.vcftools_idepth.collect{it[1]})
    ch_multiqc_files = ch_multiqc_files.mix(VCFTOOLS_MANY.out.vcftools_imiss.collect{it[1]})

    ch_versions = ch_versions.mix(FASTQC.out.versions.first())
    ch_versions = ch_versions.mix(TRIMMOMATIC.out.versions.first())
    ch_versions = ch_versions.mix(STACKS_PROCESS_RADTAGS.out.versions.first())
    ch_versions = ch_versions.mix(VCFTOOLS_MANY.out.versions.first())


    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name:  'radqc_software_'  + 'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }


    //
    // MODULE: MultiQC
    //
    ch_multiqc_config        = Channel.fromPath(
        "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config = params.multiqc_config ?
        Channel.fromPath(params.multiqc_config, checkIfExists: true) :
        Channel.empty()
    ch_multiqc_logo          = params.multiqc_logo ?
        Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
        Channel.empty()

    summary_params      = paramsSummaryMap(
        workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
        file(params.multiqc_methods_description, checkIfExists: true) :
        file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description))

    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_methods_description.collectFile(
            name: 'methods_description_mqc.yaml',
            sort: true
        )
    )

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        [],
        []
    )

    emit:multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
