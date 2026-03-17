# nf-lane-merge-trim

A Nextflow (DSL2) pipeline that:

1. **Merges per-lane FASTQ files** — all lanes belonging to the same library are concatenated into a single R1 and R2 file.
2. **Trims adapters with [fastp](https://github.com/OpenGene/fastp)** — adapter auto-detection is used; quality filtering and length filtering are disabled so that only adapter trimming is performed.

---

## Requirements

| Tool | Version |
|------|---------|
| [Nextflow](https://www.nextflow.io/) | ≥ 23.04.0 |
| Docker **or** Singularity **or** Conda | any recent version |

---

## Input

A comma-separated file with **three columns** and a header row:

```
library_name,fastq_1,fastq_2
```

| Column | Description |
|--------|-------------|
| `library_name` | Library identifier. Rows sharing the same name are treated as different lanes of the same library and will be merged. |
| `fastq_1` | Path to the R1 (forward) FASTQ file (gzipped). |
| `fastq_2` | Path to the R2 (reverse) FASTQ file (gzipped). |

Example (`fastq.csv`):

```csv
library_name,fastq_1,fastq_2
S001.A0101.SG1.1,S001.A0101.SG1.1_S0_L001_R1_001.fastq.gz,S001.A0101.SG1.1_S0_L001_R2_001.fastq.gz
S001.A0101.SG1.1,S001.A0101.SG1.1_S0_L002_R1_001.fastq.gz,S001.A0101.SG1.1_S0_L002_R2_001.fastq.gz
S001.A0101.SG1.1,S001.A0101.SG1.1_S0_L003_R1_001.fastq.gz,S001.A0101.SG1.1_S0_L003_R2_001.fastq.gz
S002.A0101.SG1.1,S002.A0101.SG1.1_S0_L001_R1_001.fastq.gz,S002.A0101.SG1.1_S0_L001_R2_001.fastq.gz
S002.A0101.SG1.1,S002.A0101.SG1.1_S0_L002_R1_001.fastq.gz,S002.A0101.SG1.1_S0_L002_R2_001.fastq.gz
```

---

## Usage

```bash
nextflow run main.nf \
    --input  fastq.csv \
    --outdir results \
    -profile docker
```

### Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--input` | `fastq.csv` | Path to the input CSV file |
| `--outdir` | `results` | Directory where output files are published |
| `--help` | — | Print help message and exit |

### Profiles

| Profile | Description |
|---------|-------------|
| `docker` | Run with Docker (recommended for local use) |
| `singularity` | Run with Singularity (recommended for HPC) |
| `conda` | Run with Conda |
| `test` | Use the bundled test dataset (`tests/fastq.csv`) |
| `<institution>` | Any [nf-core institutional profile](https://github.com/nf-core/configs) (e.g. `-profile uppmax`) |

---

## Output

```
results/
├── trimmed/         # Adapter-trimmed lane-merged FASTQs libraries (final output)
│   ├── <library>_R1.trimmed.fastq.gz
│   └── <library>_R2.trimmed.fastq.gz
└── fastp/           # fastp QC reports (per lane-merged library)
    ├── <library>.fastp.json
    └── <library>.fastp.html
```

---

## Pipeline steps

```
fastq.csv
    │
    ▼
[MERGE_LANES]  cat per-lane FASTQs (sorted by filename) into one R1 / R2
    │
    ▼
[FASTP]        adapter trimming only
               (--detect_adapter_for_pe, --disable_quality_filtering,
                --disable_length_filtering)
    │
    ▼
results/trimmed/   +   results/fastp/
```

---

## Testing

The repository includes a small test dataset under `tests/`.

```bash
# Stub run — validates pipeline logic without executing any tools
nextflow run main.nf -profile test -stub

# Real run with Docker
nextflow run main.nf -profile test,docker
```

Test data: two libraries (`LIB_A` across 2 lanes, `LIB_B` across 1 lane) with minimal 2-read FASTQ files.

---