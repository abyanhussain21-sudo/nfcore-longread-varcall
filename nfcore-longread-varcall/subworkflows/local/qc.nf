/*
 * QC — read-level quality control.
 *
 * Runs FastQC and NanoPlot in parallel on the raw FASTQ. Both outputs
 * feed the final MultiQC report. NanoPlot is more informative for HiFi
 * (read length distribution, N50); FastQC is a sanity check.
 */

include { FASTQC   } from '../../modules/local/fastqc'
include { NANOPLOT } from '../../modules/local/nanoplot'

workflow QC {
    take:
    reads     // [meta, fastq]

    main:
    ch_versions = Channel.empty()

    FASTQC( reads )
    NANOPLOT( reads )

    ch_versions = ch_versions.mix(FASTQC.out.versions, NANOPLOT.out.versions)

    emit:
    fastqc_zip   = FASTQC.out.zip
    nanoplot_txt = NANOPLOT.out.txt
    versions     = ch_versions
}
