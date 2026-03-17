process MERGE_LANES {
    tag "$library"

    input:
    tuple val(library), path(r1_files), path(r2_files)

    output:
    tuple val(library), path("${library}_R1.merged.fastq.gz"), path("${library}_R2.merged.fastq.gz"), emit: reads

    script:
    // Sort file lists so that lane order is deterministic (L001 < L002 < ...)
    def sorted_r1 = r1_files instanceof List ? r1_files.sort().join(' ') : r1_files
    def sorted_r2 = r2_files instanceof List ? r2_files.sort().join(' ') : r2_files
    """
    cat ${sorted_r1} > ${library}_R1.merged.fastq.gz
    cat ${sorted_r2} > ${library}_R2.merged.fastq.gz
    """

    stub:
    """
    touch ${library}_R1.merged.fastq.gz
    touch ${library}_R2.merged.fastq.gz
    """
}
