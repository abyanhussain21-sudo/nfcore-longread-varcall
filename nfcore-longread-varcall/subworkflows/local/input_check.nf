/*
 * INPUT_CHECK — validate the samplesheet and emit channels.
 *
 * Why a Python validator instead of nf-schema's CSV validator?
 *   nf-schema can validate columns and types but it cannot easily check
 *   that referenced files (FASTQs, FASTAs) actually exist on disk and
 *   are readable. The Python helper does both, with friendly error
 *   messages — this is what nf-core/sarek does too. nf-schema still
 *   validates *parameters* via nextflow_schema.json.
 *
 * Outputs:
 *   reads     - tuple [meta, fastq]
 *   reference - tuple [meta, fasta]   (fasta + .fai produced downstream)
 *   versions  - versions.yml stub
 */

workflow INPUT_CHECK {

    take:
    samplesheet     // path to CSV

    main:

    // Run the Python validator. It rewrites the CSV into a normalised
    // form (`samplesheet.valid.csv`) which is then parsed below.
    SAMPLESHEET_CHECK( samplesheet )

    ch_reads = SAMPLESHEET_CHECK.out.csv
        .splitCsv ( header: true, sep: ',' )
        .map { row ->
            def meta = [
                id          : row.sample_id,
                single_end  : false,
                platform    : 'PACBIO_HIFI'
            ]
            tuple( meta, file(row.fastq, checkIfExists: true) )
        }

    ch_reference = SAMPLESHEET_CHECK.out.csv
        .splitCsv ( header: true, sep: ',' )
        .map { row ->
            def meta = [ id: row.sample_id, single_end: false, platform: 'PACBIO_HIFI' ]
            tuple( meta, file(row.reference, checkIfExists: true) )
        }
        // Most users supply the same reference for every sample; collapse
        // duplicates so we don't run faidx N times. We unique on the
        // reference path (a Path), then re-wrap with a meta map keyed on
        // the basename. Wrapping in a single-element list before
        // `.unique()` would break the channel-of-Paths semantics.
        .map { meta, fa -> fa }
        .unique()
        .map { fa -> tuple( [ id: fa.getBaseName() ], fa ) }

    emit:
    reads     = ch_reads
    reference = ch_reference
    versions  = SAMPLESHEET_CHECK.out.versions
}


/*
 * Inline process — small enough to live alongside the subworkflow.
 * It calls bin/check_samplesheet.py to do the actual validation.
 */
process SAMPLESHEET_CHECK {
    tag    "${samplesheet.getName()}"
    label  'process_single'

    conda     'conda-forge::python=3.11'
    container 'quay.io/biocontainers/python:3.11--1'

    input:
    path samplesheet

    output:
    path '*.valid.csv'  , emit: csv
    path  "versions.yml", emit: versions

    script:
    // Resolve relative paths inside the samplesheet against projectDir so
    // the test profile's repo-relative paths (tests/test_data/...) work
    // even though the samplesheet itself is staged into Nextflow's work dir.
    """
    check_samplesheet.py \\
        --input   $samplesheet \\
        --output  ${samplesheet.getBaseName()}.valid.csv \\
        --basedir ${projectDir}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$( python --version | sed 's/^Python //' )
    END_VERSIONS
    """
}
