# tests/

Test fixtures for `nfcore-longread-varcall`.

## What's here

| File | Purpose |
|------|---------|
| `samplesheet_test.csv` | One-row samplesheet pointing at the synthetic FASTQ + reference. Used by `-profile test`. |
| `test_data/ref.fa` | 100 kb synthetic single-chromosome reference, 45% GC, deterministic (`random.seed(42)`). |
| `test_data/hifi.fastq.gz` | 1,000 simulated HiFi-like reads, lognormal length ~10 kb, 0.5% substitution error. |
| `test_data/PLANTED_VARIANTS.tsv` | Truth manifest of variants planted into the synthetic data. Bytes match `ref.fa`. |

## Regenerating the test data

```bash
python3 bin/make_test_data.py --outdir tests/test_data
```

The generator is deterministic — re-running it should produce a byte-identical dataset.

## What this fixture is — and isn't

**This is a SMOKE TEST, not a recall benchmark.**

The test profile verifies the pipeline runs end-to-end on synthetic HiFi-like data and produces non-empty VCFs from DeepVariant and Sniffles2. It does **NOT** assert that all planted variants are recovered — read coverage, the simulated error model, and DeepVariant's PACBIO model trained on real biology mean recall on this synthetic dataset is not predictive of real-world performance. `PLANTED_VARIANTS.tsv` exists as documentation for future Genome-in-a-Bottle benchmarking, which is on the roadmap (see README §What I would add next).

In practice the pipeline may recover only a subset of the planted variants on this fixture. That is expected and acceptable for a smoke test. The asserts in CI check that the pipeline executes cleanly and writes the expected output files — not that variant calls match the truth.

## Truth file format

`PLANTED_VARIANTS.tsv` is a tab-separated file with header `#CHROM POS REF ALT TYPE NOTE`. Coordinates are 1-based (VCF convention). The TYPE column is `SNV` or `SV`; for SVs the ALT is a symbolic allele (`<DEL>`, `<INS>`) and the length / het ratio / inserted sequence are recorded in NOTE.
