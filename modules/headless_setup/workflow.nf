#!/usr/bin/env nextflow
nextflow.enable.dsl=2 

process WORKFLOW_DB{
    publishDir "data/workflow", mode: 'copy'

    container 'fcyucn/fragpipe:latest'

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