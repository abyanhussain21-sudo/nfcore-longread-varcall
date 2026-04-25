#!/usr/bin/env nextflow
/*
 * ============================================================================
 *  nfcore-longread-varcall
 *  Haplotype-aware variant calling from PacBio HiFi long reads.
 *
 *  Author : Abyan Hussain  (https://github.com/abyanhussain21-sudo)
 *  Repo   : https://github.com/abyanhussain21-sudo/nfcore-longread-varcall
 *  Licence: MIT
 *
 *  This is the entry workflow. It does only orchestration:
 *      input_check  →  qc  ┐
 *                          ├→  alignment  →  variant_calling  →  reporting
 *  All real work lives in subworkflows/local/*.nf and the modules under
 *  modules/local/*.nf — one process per file, nf-core convention.
 * ============================================================================
 */

nextflow.enable.dsl = 2

// ---- Subworkflows ---------------------------------------------------------
include { INPUT_CHECK     } from './subworkflows/local/input_check'
include { QC              } from './subworkflows/local/qc'
include { ALIGNMENT       } from './subworkflows/local/alignment'
include { VARIANT_CALLING } from './subworkflows/local/variant_calling'
include { REPORTING       } from './subworkflows/local/reporting'


// ---- Help / version short-circuits ---------------------------------------
def helpMessage() {
    log.info """
    ============================================================================
      nfcore-longread-varcall  v${workflow.manifest.version}
      ${workflow.manifest.description}
    ----------------------------------------------------------------------------
      Quickstart:
        nextflow run . -profile test,docker

      Real run:
        nextflow run . \\
            --input samplesheet.csv \\
            --reference /path/to/ref.fa \\
            --outdir results \\
            -profile docker

      Stage toggles:  --skip_snv  --skip_sv  --skip_qc  --skip_multiqc
      Filter knobs :  --min_qual 20  --min_dp 10
      Resources    :  --max_cpus 16 --max_memory 64.GB --max_time 24.h

      Full parameter docs:  docs/parameters.md  or  --help
    ============================================================================
    """.stripIndent()
}

if (params.help) { helpMessage() ; exit 0 }
if (params.version) { log.info "${workflow.manifest.name} v${workflow.manifest.version}"; exit 0 }


// ---- Sanity checks --------------------------------------------------------
if (!params.input) {
    log.error "Missing required parameter --input (samplesheet CSV). See docs/usage.md."
    exit 1
}
if (!params.reference && !file(params.input).exists()) {
    log.error "Missing both --reference and a reachable samplesheet at --input."
    exit 1
}


// ---- Banner ---------------------------------------------------------------
log.info """
============================================================================
  nfcore-longread-varcall  v${workflow.manifest.version}
  Author : Abyan Hussain
----------------------------------------------------------------------------
  input          : ${params.input}
  reference      : ${params.reference}
  outdir         : ${params.outdir}
  skip_snv       : ${params.skip_snv}
  skip_sv        : ${params.skip_sv}
  skip_qc        : ${params.skip_qc}
  skip_multiqc   : ${params.skip_multiqc}
  min_qual / min_dp : ${params.min_qual} / ${params.min_dp}
============================================================================
""".stripIndent()


/*
 * ----------------------------------------------------------------------------
 *  Main workflow
 * ----------------------------------------------------------------------------
 */
workflow {

    // 1. INPUT VALIDATION
    INPUT_CHECK( file(params.input, checkIfExists: true) )
    ch_reads     = INPUT_CHECK.out.reads     // [meta, fastq]
    ch_reference = INPUT_CHECK.out.reference // [meta, fasta]

    // Collect version YAMLs for the final MultiQC report.
    ch_versions = Channel.empty()
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

    // 2. QC (FastQC + NanoPlot)
    ch_qc_files = Channel.empty()
    if (!params.skip_qc) {
        QC( ch_reads )
        ch_qc_files = ch_qc_files
            .mix(QC.out.fastqc_zip.map { meta, f -> f })
            .mix(QC.out.nanoplot_txt.map { meta, f -> f })
        ch_versions = ch_versions.mix(QC.out.versions)
    }

    // 3 + 4. ALIGNMENT  (minimap2 → sort → index → flagstat → mosdepth)
    ALIGNMENT( ch_reads, ch_reference )
    ch_bam_bai   = ALIGNMENT.out.bam_bai
    ch_fasta_fai = ALIGNMENT.out.fasta_fai
    ch_qc_files = ch_qc_files
        .mix(ALIGNMENT.out.flagstat.map  { meta, f -> f })
        .mix(ALIGNMENT.out.mosdepth.map  { meta, f -> f })
    ch_versions = ch_versions.mix(ALIGNMENT.out.versions)

    // 5 + 6 + 7. VARIANT CALLING  (DeepVariant + Sniffles2 + bcftools)
    VARIANT_CALLING( ch_bam_bai, ch_fasta_fai )
    ch_qc_files = ch_qc_files
        .mix(VARIANT_CALLING.out.bcftools_stats.map { meta, f -> f })
    ch_versions = ch_versions.mix(VARIANT_CALLING.out.versions)

    // 8. REPORTING  (MultiQC)
    if (!params.skip_multiqc) {
        REPORTING( ch_qc_files.collect(), file(params.multiqc_config) )
    }
}


/*
 * ----------------------------------------------------------------------------
 *  Completion handler — log success / failure for shell scripts wrapping us.
 * ----------------------------------------------------------------------------
 */
workflow.onComplete {
    log.info ( workflow.success
        ? "\n[OK] Pipeline completed. Results -> ${params.outdir}\n"
        : "\n[FAIL] Pipeline finished with errors. Inspect .nextflow.log\n" )
}
