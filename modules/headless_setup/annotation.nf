#!/usr/bin/env nextflow
nextflow.enable.dsl=2 

process MANIFEST{
    publishDir "data/manifest", mode: 'copy'
    
    input:
        val input_folder_workflow
        val mode

    output:
        path 'generated_manifest.fp-manifest'

    script:
    """
    rm -rf $baseDir/data/manifest

    echo $input_folder_workflow

    bash $baseDir/templates/annotation_gen.sh $input_folder_workflow $mode
    """
}