/*
 * ALIGNMENT — minimap2 (map-hifi) → sort → index → flagstat + mosdepth.
 *
 * Emits a (meta, bam, bai) tuple for variant_calling and the QC outputs
 * for the aggregated MultiQC report. Reference also gets a .fai indexed
 * here so DeepVariant/Sniffles2 don't each need to do it.
 */

include { MINIMAP2_ALIGN    } from '../../modules/local/minimap2_align'
include { SAMTOOLS_SORT     } from '../../modules/local/samtools_sort'
include { SAMTOOLS_INDEX    } from '../../modules/local/samtools_index'
include { SAMTOOLS_FLAGSTAT } from '../../modules/local/samtools_flagstat'
include { MOSDEPTH          } from '../../modules/local/mosdepth'

// Tiny inline process to faidx the reference — too small to deserve its
// own file. nf-core sometimes pulls SAMTOOLS_FAIDX from nf-core/modules
// but for one call we keep it local.
process FAIDX {
    tag    "${meta.id}"
    label  'process_single'

    conda     'bioconda::samtools=1.20'
    container 'quay.io/biocontainers/samtools:1.20--h50ea8bc_0'

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path(fasta), path("${fasta}.fai"), emit: fasta_fai

    script:
    """
    samtools faidx $fasta
    """
}

workflow ALIGNMENT {
    take:
    reads        // [meta, fastq]
    reference    // [meta, fasta]

    main:
    ch_versions = Channel.empty()

    // Index the reference once.
    FAIDX( reference )
    ch_fasta_fai = FAIDX.out.fasta_fai

    // Align — minimap2 needs the bare fasta channel, not fasta+fai.
    MINIMAP2_ALIGN( reads, reference )
    ch_versions = ch_versions.mix(MINIMAP2_ALIGN.out.versions)

    // Sort.
    SAMTOOLS_SORT( MINIMAP2_ALIGN.out.bam )
    ch_versions = ch_versions.mix(SAMTOOLS_SORT.out.versions)

    // Index.
    SAMTOOLS_INDEX( SAMTOOLS_SORT.out.bam )
    ch_versions = ch_versions.mix(SAMTOOLS_INDEX.out.versions)

    // Join sorted BAM with its BAI on meta.
    ch_bam_bai = SAMTOOLS_SORT.out.bam
        .join(SAMTOOLS_INDEX.out.bai, by: 0)   // [meta, bam, bai]

    // Alignment QC.
    SAMTOOLS_FLAGSTAT( ch_bam_bai )
    MOSDEPTH         ( ch_bam_bai )
    ch_versions = ch_versions
        .mix(SAMTOOLS_FLAGSTAT.out.versions)
        .mix(MOSDEPTH.out.versions)

    emit:
    bam_bai   = ch_bam_bai            // [meta, bam, bai]
    fasta_fai = ch_fasta_fai          // [meta, fasta, fai]
    flagstat  = SAMTOOLS_FLAGSTAT.out.flagstat
    mosdepth  = MOSDEPTH.out.summary
    versions  = ch_versions
}
