#!/usr/bin/env nextflow
nextflow.enable.dsl=2 


process FRAGPIPE{
    errorStrategy 'ignore'

    publishDir "output/fragpipe", mode: 'move'
    
    container 'fcyucn/fragpipe:latest'
    //containerOptions '--cleanenv --bind ${launchDir}/data/workflow/'

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
        //path 'experiment_annotation.tsv'
        //path 'protein_table.tsv'

    """
    echo "Running FragPipe with all headless parameters:"

    ls /fragpipe_bin/

    mkdir output_folder_fragpipe

    echo $workflow
    echo $manifest

    fp_version=\$(ls /fragpipe_bin/ | grep fragPipe | cut -d'-' -f2)

    #/fragpipe_bin/fragPipe-\$fp_version/fragpipe/bin/fragpipe --help || true

    #mv $launchDir/output/fragpipe/output_folder_fragpipe output_folder_fragpipe

    pip list

    ls $launchDir/data/workflow/

    ls $projectDir/config_tools/

    if [[ $mode == "DIA" ]] && [[ $diann_download != "" ]]
    then
        sed -i "s/^diann.run-dia-nn=true/diann.run-dia-nn=false/" "${launchDir}/data/workflow/selected_workflow_db.workflow"

        echo "Running FragPipe with new version of DIA-NN"
        /fragpipe_bin/fragPipe-\$fp_version/fragpipe/bin/fragpipe --headless \
        --workflow "${launchDir}/data/workflow/selected_workflow_db.workflow" \
        --manifest "${launchDir}/data/manifest/generated_manifest.fp-manifest" \
        --workdir "output_folder_fragpipe" \
        --config-tools-folder "${projectDir}/config_tools" \
        || true

        /fragpipe_bin/fragPipe-\$fp_version/fragpipe/bin/fragpipe --headless \
        --workflow "${launchDir}/data/workflow/diann.workflow" \
        --manifest "${launchDir}/data/manifest/generated_manifest.fp-manifest" \
        --workdir "output_folder_fragpipe" \
        --config-tools-folder "${projectDir}/config_tools" \
        --config-diann "${projectDir}/config_tools/diann/diann/diann-linux" \
        || true
    else
        echo "Running FragPipe"
        /fragpipe_bin/fragPipe-\$fp_version/fragpipe/bin/fragpipe --headless \
        --workflow "${launchDir}/data/workflow/selected_workflow_db.workflow" \
        --manifest "${launchDir}/data/manifest/generated_manifest.fp-manifest" \
        --workdir "output_folder_fragpipe" \
        --config-tools-folder "${projectDir}/config_tools" \
        --config-python /usr/bin/python3 \
        || true
    fi

    echo "FragPipe finished"

    head $launchDir/data/manifest/generated_manifest.fp-manifest

    echo $launchDir
    echo \$fp_version

    head $launchDir/data/workflow/selected_workflow_db.workflow
    head $launchDir/data/workflow/diann.workflow
    head $launchDir/data/manifest/generated_manifest.fp-manifest

    """
}
