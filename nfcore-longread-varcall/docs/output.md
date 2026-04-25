# Output

The pipeline writes everything under `--outdir` (default `./results`). The structure mirrors the pipeline stages.

```
results/
├── qc/
│   ├── fastqc/<sample_id>/
│   │   ├── <sample_id>_fastqc.html
│   │   └── <sample_id>_fastqc.zip
│   ├── nanoplot/<sample_id>/
│   │   ├── <sample_id>.NanoPlot-report.html
│   │   ├── <sample_id>.NanoStats.txt
│   │   └── *.png
│   ├── samtools/<sample_id>/
│   │   └── <sample_id>.flagstat
│   └── mosdepth/<sample_id>/
│       ├── <sample_id>.mosdepth.summary.txt
│       └── <sample_id>.regions.bed.gz
├── alignment/<sample_id>/
│   ├── <sample_id>.sorted.bam
│   └── <sample_id>.sorted.bam.bai
├── variants/
│   ├── snv/<sample_id>/
│   │   ├── <sample_id>.deepvariant.vcf.gz
│   │   ├── <sample_id>.snv.norm.vcf.gz
│   │   ├── <sample_id>.snv.filtered.vcf.gz
│   │   ├── <sample_id>.snv.filtered.vcf.gz.tbi
│   │   └── <sample_id>.snv.stats.txt
│   └── sv/<sample_id>/
│       ├── <sample_id>.sniffles.vcf.gz
│       ├── <sample_id>.sv.norm.vcf.gz
│       ├── <sample_id>.sv.filtered.vcf.gz
│       ├── <sample_id>.sv.filtered.vcf.gz.tbi
│       └── <sample_id>.sv.stats.txt
├── multiqc/
│   ├── multiqc_report.html
│   └── multiqc_data/
└── pipeline_info/
    ├── execution_report_<timestamp>.html
    ├── execution_timeline_<timestamp>.html
    ├── execution_trace_<timestamp>.txt
    └── pipeline_dag_<timestamp>.html
```

## What each file contains

### Read QC

- **FastQC HTML/ZIP** — per-base quality, GC distribution, sequence length. FastQC's adapter checks are designed for short reads and are usually uninformative for HiFi; the per-base quality plot is still useful as a sanity check.
- **NanoPlot HTML + NanoStats.txt** — read length distribution, N50, mean quality. The most informative QC for HiFi.

### Alignment QC

- **flagstat** — count of mapped / unmapped / supplementary / duplicate reads. Quick overall mapping check.
- **mosdepth summary + regions BED** — depth-of-coverage in 1 kb bins, plus genome-wide summary statistics.

### Alignment

- **sorted.bam / .bam.bai** — coordinate-sorted, indexed alignments. Use directly with IGV or downstream tools.

### Variant calls

- **deepvariant.vcf.gz** — raw small-variant calls (SNVs + small indels) from DeepVariant's PACBIO model.
- **snv.norm.vcf.gz** — normalised: multiallelics split, indels left-aligned against the reference.
- **snv.filtered.vcf.gz** — `QUAL >= --min_qual` and `INFO/DP >= --min_dp` retained.
- **snv.stats.txt** — `bcftools stats` summary (Ti/Tv, indel-length distribution, allele-frequency spectrum).
- **sniffles.vcf.gz** / **sv.norm.vcf.gz** / **sv.filtered.vcf.gz** / **sv.stats.txt** — same pipeline applied to Sniffles2 SV calls.

### Reporting

- **multiqc_report.html** — single-page HTML aggregating FastQC, NanoPlot, samtools, mosdepth, and bcftools stats for every sample.

### Pipeline info

- Execution report, timeline, trace, and DAG — Nextflow's built-in run metadata. Useful for debugging resource use.
