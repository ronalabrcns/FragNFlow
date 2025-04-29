#!/usr/bin/env nextflow
nextflow.enable.dsl=2 

process DATABASE{
    publishDir "data/database", mode: 'copy'

    container 'sznistvan/philo:latest'

    input:
        path input_fasta
        val decoy_tag

    output:
        val true

    script:
        template 'database.sh'
}
