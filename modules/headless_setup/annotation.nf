#!/usr/bin/env nextflow
nextflow.enable.dsl=2 

/* =========================================================================================
  Description :   Process for generating the input manifest file.
 ==========================================================================================
 */

process MANIFEST{
    publishDir "data/manifest", mode: 'copy'
    
    input:
        val input_folder_workflow
        val mode
        val use_custom_manifest
        val manifest_file

    output:
        path 'generated_manifest.fp-manifest'

    script:
    """
    rm -rf $baseDir/data/manifest

    echo $input_folder_workflow

    bash $baseDir/templates/annotation_gen.sh $input_folder_workflow $mode $use_custom_manifest $manifest_file
    """
}