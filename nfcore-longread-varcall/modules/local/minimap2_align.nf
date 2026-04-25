/*
 * MINIMAP2_ALIGN — long-read alignment with the map-hifi preset.
 *
 * `-ax map-hifi` is the canonical preset for PacBio HiFi reads:
 *   - tuned for ~99.9% accuracy reads
 *   - uses asymmetric error model
 *   - recommended by Heng Li for HiFi (vs map-pb for older CLR data)
 *
 * The output is a *raw* SAM piped into samtools view → BAM. Sorting is
 * a separate process (SAMTOOLS_SORT) so each step is restartable and the
 * BAM index can be a separate process too — nf-core idiom.
 *
 * Inputs : tuple (meta, FASTQ), tuple (meta2, reference FASTA)
 * Outputs: tuple (meta, BAM)
 */
process MINIMAP2_ALIGN {
    tag    "${meta.id}"
    label  'process_high'

    // Multi-tool container: minimap2 piped into samtools view.
    conda     'bioconda::minimap2=2.28 bioconda::samtools=1.20'
    container 'quay.io/biocontainers/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:1679e915ddb9d6b4abda91880c4b48857d471bd8-0'

    input:
    tuple val(meta) , path(reads)
    tuple val(meta2), path(reference)

    output:
    tuple val(meta), path("*.bam"), emit: bam
    path  "versions.yml"          , emit: versions

    script:
    def args = task.ext.args ?: '-ax map-hifi --MD -Y'
    def prefix = task.ext.prefix ?: "${meta.id}"
    // Tag the @RG so downstream tools (DeepVariant, GATK) have sample id.
    def rg = "@RG\\\\tID:${meta.id}\\\\tSM:${meta.id}\\\\tPL:${meta.platform ?: 'PACBIO_HIFI'}\\\\tLB:${meta.id}"
    """
    minimap2 \\
        $args \\
        -t $task.cpus \\
        -R '${rg}' \\
        $reference \\
        $reads \\
      | samtools view -@ $task.cpus -bS -o ${prefix}.bam -

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minimap2: \$( minimap2 --version )
        samtools: \$( samtools --version | head -n1 | awk '{print \$2}' )
    END_VERSIONS
    """
}
