#!/usr/bin/env nextflow

/*
========================================================================================
    nf-lane_merge_trim
========================================================================================
    Merge per-lane FASTQ files by library, then perform adapter trimming with fastp.
    Input : CSV file with columns: library_name, fastq_1, fastq_2
    Output: One adapter-trimmed R1/R2 pair per library
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

include { MERGE_LANES } from './modules/local/merge_lanes/main'
include { FASTP        } from './modules/local/fastp/main'

// -----------------------------------------------------------------------
// Help message
// -----------------------------------------------------------------------
def showHelp() {
    log.info """
    =========================================
     nf-lane_merge_trim
    =========================================
    Usage:
        nextflow run main.nf [options]

    Options:
        --input     Path to input CSV file  [default: ${params.input}]
        --outdir    Output directory         [default: ${params.outdir}]
        --help      Show this message

    CSV format (header required):
        library_name,fastq_1,fastq_2

    Example:
        nextflow run main.nf --input fastq.csv --outdir results -profile docker
    """.stripIndent()
}

if (params.help) {
    showHelp()
    exit 0
}

// -----------------------------------------------------------------------
// Validate input
// -----------------------------------------------------------------------
def inputFile = file(params.input)
if (!inputFile.exists()) {
    error "Input CSV not found: ${params.input}"
}

// -----------------------------------------------------------------------
// Workflow
// -----------------------------------------------------------------------
workflow {

    // Parse CSV → [library_name, file(r1), file(r2)]
    ch_raw = Channel
        .fromPath(params.input)
        .splitCsv(header: true)
        .map { row ->
            def library = row.library_name
            def r1      = file(row.fastq_1)
            def r2      = file(row.fastq_2)

            if (!r1.exists()) log.warn "R1 file not found: ${r1}"
            if (!r2.exists()) log.warn "R2 file not found: ${r2}"

            return [ library, r1, r2 ]
        }

    // Group all lanes for the same library together
    // After groupTuple: [library, [r1_L001, r1_L002, ...], [r2_L001, r2_L002, ...]]
    ch_grouped = ch_raw
        .groupTuple(by: 0)

    // Step 1: merge lanes
    MERGE_LANES(ch_grouped)

    // Step 2: adapter trimming
    FASTP(MERGE_LANES.out.reads)
}
