include { VCFTOOLS as VCFTOOLS_RELATEDNESS2 } from '../../../modules/nf-core/vcftools/main' 
include { VCFTOOLS as VCFTOOLS_HET } from '../../../modules/nf-core/vcftools/main' 
include { VCFTOOLS as VCFTOOLS_DEPTH } from '../../../modules/nf-core/vcftools/main' 
include { VCFTOOLS as VCFTOOLS_IMISS } from '../../../modules/nf-core/vcftools/main' 


// Inspired by nf-core/sarek/subworkflows/vcf_qc_bcftools_vcftools
workflow VCFTOOLS_MANY {
    take:
    vcf

    main:

    versions = Channel.empty()

    VCFTOOLS_RELATEDNESS2(vcf, [], [])
    VCFTOOLS_HET(vcf, [], [])
    VCFTOOLS_DEPTH(vcf, [], [])
    VCFTOOLS_IMISS(vcf, [], [])

    versions = versions.mix(VCFTOOLS_RELATEDNESS2.out.versions)

    emit:
    vcftools_relatedness2  = VCFTOOLS_RELATEDNESS2.out.relatedness2
    vcftools_het           = VCFTOOLS_HET.out.heterozygosity
    vcftools_idepth         = VCFTOOLS_DEPTH.out.idepth
    vcftools_imiss         = VCFTOOLS_IMISS.out.missing_individual

    versions
}