/*
 * VARIANT_CALLING — DeepVariant (SNV/indel) + Sniffles2 (SV), each
 * normalised, filtered, and summarised with bcftools.
 *
 * Stage toggles --skip_snv / --skip_sv let users run only one branch.
 * Both branches reuse the same BCFTOOLS_NORM/FILTER/STATS modules; the
 * meta map carries `vartype` ('snv'|'sv') so publishDir routes outputs
 * correctly without duplicating modules.
 */

include { DEEPVARIANT     } from '../../modules/local/deepvariant'
include { SNIFFLES        } from '../../modules/local/sniffles'
include { BCFTOOLS_NORM as BCFTOOLS_NORM_SNV   } from '../../modules/local/bcftools_norm'
include { BCFTOOLS_NORM as BCFTOOLS_NORM_SV    } from '../../modules/local/bcftools_norm'
include { BCFTOOLS_FILTER as BCFTOOLS_FILTER_SNV } from '../../modules/local/bcftools_filter'
include { BCFTOOLS_FILTER as BCFTOOLS_FILTER_SV  } from '../../modules/local/bcftools_filter'
include { BCFTOOLS_STATS  as BCFTOOLS_STATS_SNV } from '../../modules/local/bcftools_stats'
include { BCFTOOLS_STATS  as BCFTOOLS_STATS_SV  } from '../../modules/local/bcftools_stats'

workflow VARIANT_CALLING {
    take:
    bam_bai     // [meta, bam, bai]
    fasta_fai   // [meta, fasta, fai]

    main:
    ch_versions  = Channel.empty()
    ch_stats_all = Channel.empty()

    // ---- SNV branch (DeepVariant) -----------------------------------
    if (!params.skip_snv) {
        DEEPVARIANT( bam_bai, fasta_fai )

        // Tag meta with vartype for routing.
        ch_snv = DEEPVARIANT.out.vcf
            .join(DEEPVARIANT.out.tbi, by: 0)
            .map { meta, vcf, tbi ->
                tuple( meta + [ vartype: 'snv' ], vcf, tbi )
            }

        BCFTOOLS_NORM_SNV  ( ch_snv, fasta_fai )
        ch_snv_norm = BCFTOOLS_NORM_SNV.out.vcf.join(BCFTOOLS_NORM_SNV.out.tbi, by: 0)

        BCFTOOLS_FILTER_SNV( ch_snv_norm )
        ch_snv_filt = BCFTOOLS_FILTER_SNV.out.vcf.join(BCFTOOLS_FILTER_SNV.out.tbi, by: 0)

        BCFTOOLS_STATS_SNV ( ch_snv_filt )

        ch_stats_all = ch_stats_all.mix(BCFTOOLS_STATS_SNV.out.stats)
        ch_versions  = ch_versions
            .mix(DEEPVARIANT.out.versions)
            .mix(BCFTOOLS_NORM_SNV.out.versions)
            .mix(BCFTOOLS_FILTER_SNV.out.versions)
            .mix(BCFTOOLS_STATS_SNV.out.versions)
    }

    // ---- SV branch (Sniffles2) --------------------------------------
    if (!params.skip_sv) {
        SNIFFLES( bam_bai, fasta_fai )

        ch_sv = SNIFFLES.out.vcf
            .join(SNIFFLES.out.tbi, by: 0)
            .map { meta, vcf, tbi ->
                tuple( meta + [ vartype: 'sv' ], vcf, tbi )
            }

        BCFTOOLS_NORM_SV  ( ch_sv, fasta_fai )
        ch_sv_norm = BCFTOOLS_NORM_SV.out.vcf.join(BCFTOOLS_NORM_SV.out.tbi, by: 0)

        BCFTOOLS_FILTER_SV( ch_sv_norm )
        ch_sv_filt = BCFTOOLS_FILTER_SV.out.vcf.join(BCFTOOLS_FILTER_SV.out.tbi, by: 0)

        BCFTOOLS_STATS_SV ( ch_sv_filt )

        ch_stats_all = ch_stats_all.mix(BCFTOOLS_STATS_SV.out.stats)
        ch_versions  = ch_versions
            .mix(SNIFFLES.out.versions)
            .mix(BCFTOOLS_NORM_SV.out.versions)
            .mix(BCFTOOLS_FILTER_SV.out.versions)
            .mix(BCFTOOLS_STATS_SV.out.versions)
    }

    emit:
    bcftools_stats = ch_stats_all
    versions       = ch_versions
}
