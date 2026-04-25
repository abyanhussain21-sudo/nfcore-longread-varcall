#!/usr/bin/env python3
"""
make_test_data.py — generate the synthetic test dataset.

Why hand-rolled instead of pbsim2? Because pbsim2 isn't on bioconda for
macOS arm64 and pulling a Linux container just to seed a 5-minute test
profile is overkill. The synthetic reads here are good enough to exercise
the pipeline end-to-end: minimap2 will map them, DeepVariant will see
SNVs (we plant a handful), and Sniffles2 will see one ~500 bp deletion.

What it produces (under tests/test_data/):

  ref.fa        100 kb single-chromosome FASTA, 45% GC, deterministic seed
  hifi.fastq.gz 1000 simulated HiFi reads, mean length 10 kb (lognormal),
                error rate ~0.5% (HiFi is ~99.9% but for the test profile
                we want the caller to see *something*)

Planted truth (also written to tests/test_data/PLANTED_VARIANTS.tsv):

  Five SNVs at chr1:10001/25001/40001/55001/70001 — for each, the
  actual base produced by the seeded random reference is read AT
  generation time and the ALT is chosen as a base different from
  that observed REF. The truth TSV therefore matches the FASTA
  byte-for-byte (no documentation that lies).

  One 500 bp deletion at chr1:80001 — read-side only; ~70% of reads
  spanning the window carry it (heterozygous-like).

  One 50 bp insertion at chr1:90001 — read-side only; ~70% of reads
  spanning the position carry it (heterozygous-like). Insertions are
  present in reads relative to reference by definition, so the FASTA
  is unchanged.

The pipeline is wired so the test profile loosens --min_qual / --min_dp
to 1 (synthetic QUAL/DP are low) so all planted SNVs survive filtering.

Determinism:
  random.seed(42) controls everything. Re-running this script will
  produce a byte-identical dataset, which makes CI diff-stable.
"""

from __future__ import annotations

import argparse
import gzip
import random
from pathlib import Path

SEED = 42
REF_LEN = 100_000
GC_CONTENT = 0.45
N_READS = 1000
MEAN_READ_LEN = 10_000
SD_LOG_LEN = 0.25      # lognormal sigma — gives a tight HiFi-ish distribution
ERROR_RATE = 0.005     # 0.5% — slightly noisier than real HiFi (≈0.1%) so calls form

# Planted SNV positions (0-based). The REF base is read from the
# generated reference at runtime; the ALT is the *preferred* alt unless
# the observed REF already equals it, in which case we pick another.
PLANTED_SNV_POSITIONS = [
    (10_000, "T"),
    (25_000, "C"),
    (40_000, "T"),
    (55_000, "G"),
    (70_000, "G"),
]
DEL_START = 80_000
DEL_LEN   = 500
INS_POS   = 90_000      # 0-based; insertion appears between positions 89_999 and 90_000
INS_LEN   = 50

ALPHABET = "ACGT"


def random_genome(length: int, gc: float) -> list[str]:
    """Produce a list (mutable) of bases with given GC%."""
    rng = random.Random(SEED)
    p_gc_each = gc / 2.0
    p_at_each = (1.0 - gc) / 2.0
    weights = [p_at_each, p_gc_each, p_gc_each, p_at_each]  # A,C,G,T
    return rng.choices(ALPHABET, weights=weights, k=length)


def plant_variants(ref: list[str]) -> tuple[list[str], list[tuple[int, str, str]]]:
    """Apply planted SNVs in-place and return (genome, observed_truth).

    For each planted position:
      - read the actual REF base produced by the seeded random reference
      - pick ALT = the configured preferred alt, unless the observed REF
        already equals it, in which case fall back to a deterministic
        alternative
      - write the genome with REF -> ALT

    The returned truth list contains (pos, observed_REF, chosen_ALT)
    tuples that match the mutated FASTA byte-for-byte. This is what
    we serialise to PLANTED_VARIANTS.tsv.

    The deletion and insertion are *not* applied here — reads carry
    them, which is how SV callers see them.
    """
    truth: list[tuple[int, str, str]] = []
    for pos, preferred_alt in PLANTED_SNV_POSITIONS:
        observed_ref = ref[pos]
        if observed_ref == preferred_alt:
            # Pick the first alphabet base different from observed_ref —
            # deterministic so reruns are stable.
            alt = next(b for b in ALPHABET if b != observed_ref)
        else:
            alt = preferred_alt
        ref[pos] = alt
        truth.append((pos, observed_ref, alt))
    return ref, truth


def fasta_from_seq(seq_str: str, name: str = "chr1") -> str:
    lines = [f">{name}"]
    for i in range(0, len(seq_str), 80):
        lines.append(seq_str[i : i + 80])
    return "\n".join(lines) + "\n"


def add_errors(read: str, rng: random.Random, rate: float) -> str:
    """Sprinkle substitution errors at the given rate."""
    if rate <= 0:
        return read
    out = []
    for b in read:
        if rng.random() < rate:
            out.append(rng.choice([x for x in ALPHABET if x != b]))
        else:
            out.append(b)
    return "".join(out)


def simulate_reads(
    ref_seq: str,
    n_reads: int,
    mean_len: int,
    sd_log: float,
    err: float,
    del_start: int,
    del_len: int,
    ins_pos: int,
    ins_len: int,
) -> tuple[list[tuple[str, str]], str]:
    """Sample reads uniformly across the genome and return (reads, ins_seq).

    Heterozygous-like SVs:
      * reads spanning the deletion window have that interval excised
        ~70% of the time
      * reads spanning the insertion position have a fixed 50 bp
        synthetic sequence inserted ~70% of the time

    The inserted sequence is generated from a deterministic RNG so the
    truth file can record its exact bases.
    """
    rng     = random.Random(SEED + 1)
    ins_rng = random.Random(SEED + 2)
    ins_seq = "".join(ins_rng.choices(ALPHABET, k=ins_len))

    reads: list[tuple[str, str]] = []

    import math
    for i in range(n_reads):
        # Lognormal length around mean_len.
        length = int(rng.lognormvariate(mu=math.log(mean_len), sigma=sd_log))
        length = max(2_000, min(length, len(ref_seq) - 1))
        start = rng.randint(0, len(ref_seq) - length)
        read = ref_seq[start : start + length]

        # Apply deletion (~70% of spanning reads).
        if start <= del_start and start + length >= del_start + del_len:
            if rng.random() < 0.7:
                local_start = del_start - start
                read = read[:local_start] + read[local_start + del_len :]

        # Apply insertion (~70% of spanning reads). The insertion is
        # placed BEFORE position `ins_pos` in reference coordinates,
        # which we translate to the local read offset.
        if start < ins_pos and start + length > ins_pos:
            if rng.random() < 0.7:
                local_offset = ins_pos - start
                read = read[:local_offset] + ins_seq + read[local_offset:]

        # Add HiFi-ish substitution errors.
        read = add_errors(read, rng, err)

        # Phred-encoded fake qualities (~Q40 = 'I')
        qual = "I" * len(read)
        name = f"read{i:05d}"
        reads.append((name, read + "\t" + qual))

    return reads, ins_seq


def write_fastq_gz(out_path: Path, reads: list[tuple[str, str]]) -> None:
    with gzip.open(out_path, "wt") as fh:
        for name, payload in reads:
            seq, qual = payload.split("\t")
            fh.write(f"@{name}\n{seq}\n+\n{qual}\n")


def write_truth(
    tsv_path: Path,
    snv_truth: list[tuple[int, str, str]],
    ins_seq: str,
) -> None:
    """Write the observed-truth TSV.

    `snv_truth` carries the ACTUAL ref bases produced by the seeded
    random reference, so the file matches the FASTA exactly.
    """
    lines = ["#CHROM\tPOS\tREF\tALT\tTYPE\tNOTE"]
    for pos, observed_ref, alt in snv_truth:
        lines.append(f"chr1\t{pos+1}\t{observed_ref}\t{alt}\tSNV\thomozygous")
    lines.append(
        f"chr1\t{DEL_START+1}\t.\t<DEL>\tSV\tlength={DEL_LEN}; ~70% of spanning reads carry it"
    )
    lines.append(
        f"chr1\t{INS_POS+1}\t.\t<INS>\tSV\tlength={INS_LEN}; ~70% of spanning reads carry it; seq={ins_seq}"
    )
    tsv_path.write_text("\n".join(lines) + "\n")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--outdir", default="tests/test_data", type=Path)
    args = ap.parse_args()
    args.outdir.mkdir(parents=True, exist_ok=True)

    print(f"[make_test_data] generating reference at {args.outdir}/ref.fa")
    ref_list = random_genome(REF_LEN, GC_CONTENT)
    ref_list, snv_truth = plant_variants(ref_list)
    ref_seq = "".join(ref_list)
    (args.outdir / "ref.fa").write_text(fasta_from_seq(ref_seq, "chr1"))

    print(f"[make_test_data] simulating {N_READS} HiFi reads")
    reads, ins_seq = simulate_reads(
        ref_seq,
        n_reads=N_READS,
        mean_len=MEAN_READ_LEN,
        sd_log=SD_LOG_LEN,
        err=ERROR_RATE,
        del_start=DEL_START,
        del_len=DEL_LEN,
        ins_pos=INS_POS,
        ins_len=INS_LEN,
    )
    write_fastq_gz(args.outdir / "hifi.fastq.gz", reads)

    print(f"[make_test_data] writing truth manifest to {args.outdir}/PLANTED_VARIANTS.tsv")
    write_truth(args.outdir / "PLANTED_VARIANTS.tsv", snv_truth, ins_seq)

    print("[make_test_data] done")


if __name__ == "__main__":
    main()
