/*
 * REPORTING — aggregate every QC artefact into a single MultiQC report.
 */

include { MULTIQC } from '../../modules/local/multiqc'

workflow REPORTING {
    take:
    qc_files       // collected list of all QC artefacts (already .collect()-ed)
    multiqc_config // path to multiqc_config.yml

    main:
    MULTIQC( qc_files, multiqc_config )

    emit:
    report   = MULTIQC.out.report
    versions = MULTIQC.out.versions
}
