#!/usr/bin/env nextflow
nextflow.enable.dsl=2 

/* =========================================================================================
 MSConverter sub-workflow processes
-----------------------------------------------------------------------------------------
 Description :   MSConverter sub-workflow for converting raw files to mzML format.
==========================================================================================
*/

process FILELIST {
    publishDir "output/filelist", mode: 'copy'
    
    output:
        path 'input_folder_filelist'

    """
    echo Generating file list
    """
}

process MSCONVERTER_FOLDER {
    input:
        val filelist
        path raw_input_folder

    output:
        env 'msconverter_folder'
    script:
    """
    msconverter_folder="${launchDir}/output/msconverter"

    while [[ "\$(ls "\$msconverter_folder" | grep .mzML | wc -l)" != "\$(ls "$raw_input_folder" | grep .raw | wc -l)" ]]; do
        echo "Waiting for msconverter to finish..."
        sleep 1
    done

    if [ -f ${raw_input_folder}/*annotation.txt ]; then
        echo "Annotation file found, moving to msconverter folder."
        cp ${raw_input_folder}/*annotation.txt \${msconverter_folder}/
    fi

    echo "All converted files moved successfully."
    """
}

process MSCONVERTER {
    //clusterOptions '--account=user132', '--job-name=nf-conv', '--partition=all'
    publishDir "output/msconverter", mode: 'move'
    container 'proteowizard/pwiz-skyline-i-agree-to-the-vendor-licenses'
    containerOptions '--cleanenv --bind $PWD:/data --writable-tmpfs'
    input:
        path input_file

    output:
        path "*.mzML"

    script:
    """
    echo $input_file
    echo ${input_file.baseName}
    echo $projectDir
    echo $workDir

    
    for file in $input_file; do
        extension="\${file##*.}"
        filename_no_ext="\${file%.\$extension}"

        mywine msconvert $input_file --32 --zlib --filter "peakPicking true 1-" --filter "zeroSamples removeExtra" --outfile \${filename_no_ext}.mzML
        
        #echo "asdasd text to file" > \${filename_no_ext}.mzML
    done

    MSCONVERTER_OUTPUT_DIR="${launchDir}/output/msconverter"
    
    """
}

process CHECK_CONVERT_SUCCESS{
    input:
        path raw_input_folder
        path msconverter_output_dir

    output:
        val true

    script:
    """
    while [[ "\$(ls "$msconverter_output_dir" | grep -c .mzML)" -eq "\$(ls "$raw_input_folder" | grep -c .raw)" ]]; do
        echo "Waiting for msconverter to finish..."
        sleep 1
    done
    """
}
