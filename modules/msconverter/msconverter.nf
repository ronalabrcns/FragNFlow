#!/usr/bin/env nextflow
nextflow.enable.dsl=2 

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
    echo "All converted files moved successfully."
    """
}

process MSCONVERTER {
    //clusterOptions '--account=sznistvan', '--job-name=nf-conv', '--partition=all'
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
    #mkdir $workDir/mountdata
    #mkdir $workDir/output_converted
    #chmod 777 $workDir/mountdata
    
    #mywine msconvert --help

    #find $input_file -maxdepth 1 -type f -print0 | xargs -0 -I{} -P -n 1 singularity exec\
    #        --cleanenv --bind $workDir/mountdata:/data --writable-tmpfs\
    #        $workDir/singularity/proteowizard-pwiz-skyline-i-agree-to-the-vendor-licenses.img\
    #        mywine msconvert {} --outdir $workDir/output_converted

    #mywine msconvert --help || true

    #singularity exec --cleanenv --bind $workDir/mountdata:/data --writable-tmpfs\
    #        $workDir/singularity/proteowizard-pwiz-skyline-i-agree-to-the-vendor-licenses.img\
    #        mywine msconvert $input_file\
    #        --32 --zlib --filter "peakPicking true 1-" --filter "zeroSamples removeExtra" --outdir output_converted
    

    #mywine msconvert $input_file\
    #    --32 --zlib --filter "peakPicking true 1-" --filter "zeroSamples removeExtra" --outfile ${input_file.baseName}.mzML

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
