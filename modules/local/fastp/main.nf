process FASTP {
    tag "$library"
    label 'process_high'

    container "${ workflow.containerEngine == 'singularity' ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/55/556474e164daf5a5e218cd5d497681dcba0645047cf24698f88e3e078eacbd09/data' :
        'community.wave.seqera.io/library/fastp:1.1.0--08aa7c5662a30d57' }"

    publishDir "${params.outdir}/trimmed",  mode: 'copy', pattern: "*.fastq.gz"
    publishDir "${params.outdir}/fastp",    mode: 'copy', pattern: "*.{json,html}"

    input:
    tuple val(library), path(r1), path(r2)

    output:
    tuple val(library), path("${library}_R1.trimmed.fastq.gz"), path("${library}_R2.trimmed.fastq.gz"), emit: reads
    path "${library}.fastp.json", emit: json
    path "${library}.fastp.html", emit: html

    script:
    """
    fastp \\
        --in1 ${r1} \\
        --in2 ${r2} \\
        --out1 ${library}_R1.trimmed.fastq.gz \\
        --out2 ${library}_R2.trimmed.fastq.gz \\
        --json ${library}.fastp.json \\
        --html ${library}.fastp.html \\
        --detect_adapter_for_pe \\
        --disable_quality_filtering \\
        --disable_length_filtering \\
        --thread ${task.cpus}
    """

    stub:
    """
    touch ${library}_R1.trimmed.fastq.gz
    touch ${library}_R2.trimmed.fastq.gz
    echo '{"summary":{"before_filtering":{"total_reads":100}}}' > ${library}.fastp.json
    touch ${library}.fastp.html
    """
}
