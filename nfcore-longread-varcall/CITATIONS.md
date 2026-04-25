# `nfcore-longread-varcall` — citations

If you use this pipeline, please cite the underlying tools.

## Pipeline

> Hussain, A. (2026). **nfcore-longread-varcall: a Nextflow DSL2 pipeline for haplotype-aware variant calling from PacBio HiFi long reads.** v0.1.0. https://github.com/abyanhussain21-sudo/nfcore-longread-varcall

## Workflow framework

- **Nextflow** — Di Tommaso, P. et al. (2017) Nextflow enables reproducible computational workflows. *Nature Biotechnology* 35, 316–319. https://doi.org/10.1038/nbt.3820
- **nf-core conventions** — Ewels, P.A. et al. (2020) The nf-core framework for community-curated bioinformatics pipelines. *Nature Biotechnology* 38, 276–278. https://doi.org/10.1038/s41587-020-0439-x

## Tools used in this pipeline

| Tool | Version | Citation |
|------|---------|----------|
| **NanoPlot** | 1.42.0 | De Coster, W. & Rademakers, R. (2023) NanoPack2: population-scale evaluation of long-read sequencing data. *Bioinformatics* 39:btad311. https://doi.org/10.1093/bioinformatics/btad311 |
| **FastQC** | 0.12.1 | Andrews, S. FastQC: a quality-control tool for high-throughput sequence data. https://www.bioinformatics.babraham.ac.uk/projects/fastqc/ |
| **minimap2** | 2.28 | Li, H. (2018) Minimap2: pairwise alignment for nucleotide sequences. *Bioinformatics* 34, 3094–3100. https://doi.org/10.1093/bioinformatics/bty191 |
| **samtools** | 1.20 | Danecek, P. et al. (2021) Twelve years of SAMtools and BCFtools. *GigaScience* 10, giab008. https://doi.org/10.1093/gigascience/giab008 |
| **mosdepth** | 0.3.8 | Pedersen, B.S. & Quinlan, A.R. (2018) Mosdepth: quick coverage calculation for genomes and exomes. *Bioinformatics* 34, 867–868. https://doi.org/10.1093/bioinformatics/btx699 |
| **DeepVariant** | 1.6.1 | Poplin, R. et al. (2018) A universal SNP and small-indel variant caller using deep neural networks. *Nature Biotechnology* 36, 983–987. https://doi.org/10.1038/nbt.4235 |
| **Sniffles2** | 2.4 | Smolka, M. et al. (2024) Detection of mosaic and population-level structural variants with Sniffles2. *Nature Biotechnology* 42, 1571–1580. https://doi.org/10.1038/s41587-023-02024-y |
| **bcftools** | 1.20 | Danecek, P. et al. (2021) Twelve years of SAMtools and BCFtools. *GigaScience* 10, giab008. https://doi.org/10.1093/gigascience/giab008 |
| **MultiQC** | 1.23 | Ewels, P. et al. (2016) MultiQC: summarize analysis results for multiple tools and samples in a single report. *Bioinformatics* 32, 3047–3048. https://doi.org/10.1093/bioinformatics/btw354 |

## Container exception

DeepVariant uses Google's official container `docker.io/google/deepvariant:1.6.1` instead of a Quay.io BioContainer because the BioConda package omits the model checkpoints. This is the same choice nf-core/sarek makes for the same reason.

## Data

- **PacBio HiFi sequencing** — Wenger, A.M. et al. (2019) Accurate circular consensus long-read sequencing improves variant detection and assembly of a human genome. *Nature Biotechnology* 37, 1155–1162. https://doi.org/10.1038/s41587-019-0217-9
