#!/usr/bin/env nextflow
nextflow.enable.dsl=2 

//====================================================
// FragPipe process
// ----------------------------------------------------
// Description :   Main process for running FragPipe in headless mode.
//====================================================

process FRAGPIPE{
    errorStrategy 'ignore'

    publishDir "output/fragpipe", mode: 'move'
    
    container "fcyucn/fragpipe:${params.fragpipe_version}"
    containerOptions "--cleanenv --bind $PWD,$HOME/.config,${params.input_folder},${launchDir},${projectDir}"

    input:
        val ready
        val manifest
        val workflow
        val base_workflow
        val ram
        val threads
        val mode
        val diann_download

    output:
        path 'output_folder_fragpipe'

    """
    echo "Running FragPipe with all headless parameters:"

    ls /fragpipe_bin/

    mkdir output_folder_fragpipe

    echo $workflow
    echo $manifest

    fp_version=\$(ls /fragpipe_bin/ | grep fragpipe | cut -d'-' -f2)

    fp_run_path="/fragpipe_bin/fragpipe-\$fp_version/fragpipe-\$fp_version/bin/fragpipe"

    if [[ $mode == "DIA" ]] && [[ $diann_download != "" ]]
    then
        sed -i "s/^diann.run-dia-nn=true/diann.run-dia-nn=false/" "${launchDir}/data/workflow/selected_workflow_db.workflow"

        echo "Running FragPipe with new version of DIA-NN"
        \$fp_run_path --headless --ram $ram --threads $threads \
        --workflow "${launchDir}/data/workflow/selected_workflow_db.workflow" \
        --manifest "${launchDir}/data/manifest/generated_manifest.fp-manifest" \
        --workdir "output_folder_fragpipe" \
        --config-tools-folder "${projectDir}/config_tools" \
        || true

        \$fp_run_path --headless --ram $ram --threads $threads \
        --workflow "${launchDir}/data/workflow/diann.workflow" \
        --manifest "${launchDir}/data/manifest/generated_manifest.fp-manifest" \
        --workdir "output_folder_fragpipe" \
        --config-tools-folder "${projectDir}/config_tools" \
        --config-diann "${projectDir}/diann/diann/diann-linux" \
        || true
    else
        echo "Running FragPipe"
        \$fp_run_path --headless --ram $ram --threads $threads \
        --workflow "${launchDir}/data/workflow/selected_workflow_db.workflow" \
        --manifest "${launchDir}/data/manifest/generated_manifest.fp-manifest" \
        --workdir "output_folder_fragpipe" \
        --config-tools-folder "${projectDir}/config_tools" \
        || true
    fi

    echo "FragPipe finished"

    """
}
