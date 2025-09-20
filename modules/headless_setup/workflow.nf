#!/usr/bin/env nextflow
nextflow.enable.dsl=2 

/* ====================================================
 Description :   Process for selecting a custom or pre-defined FragPipe workflow.
 ====================================================
 */

process WORKFLOW_DB{
    publishDir "data/workflow", mode: 'copy'

    container "fcyucn/fragpipe:${params.fragpipe_version}"
    containerOptions "--cleanenv --bind $PWD,$HOME/.config,${params.input_folder},${launchDir},${projectDir}"

    input:
        val ready
        val workflow
        val decoy_tag

    output:
        path 'selected_workflow_db.workflow'
        path 'diann.workflow'

    script:
        template 'workflow.sh'
}
