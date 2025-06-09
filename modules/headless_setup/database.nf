#!/usr/bin/env nextflow
nextflow.enable.dsl=2 

/* =========================================================================================
  Description :   Process for generating a decoy-containing database from a reference proteome FASTA file.
=========================================================================================
*/

process DATABASE{
    publishDir "data/database", mode: 'copy'

    container 'sznistvan/philo:latest'
    containerOptions "--cleanenv --bind $PWD,$HOME/.config,${params.input_folder},${launchDir},${projectDir}"

    input:
        path input_fasta
        val decoy_tag

    output:
        val true
        path 'reference_proteome_decoy.fasta'

    script:
        template 'database.sh'
}
