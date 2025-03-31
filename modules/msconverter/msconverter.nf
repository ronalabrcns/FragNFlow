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

process PULLMSCONVERTER {
    //publishDir "output/msconverter", mode: 'copy'
    container 'proteowizard/pwiz-skyline-i-agree-to-the-vendor-licenses'

    """
    echo Pulling msconverter image
    """
}

process MSCONVERTER {
    clusterOptions '--account=sznistvan', '--job-name=nf-conv', '--partition=all'
    publishDir "output/msconverter", mode: 'copy'
    //container 'proteowizard/pwiz-skyline-i-agree-to-the-vendor-licenses'
    input:
        path input_file


    script:
    """
    echo $input_file
    echo $projectDir
    echo $workDir
    #mkdir $workDir/mountdata
    #mkdir $workDir/output_converted
    chmod 777 $workDir/mountdata
    
    #mywine msconvert --help

    #find $input_file -maxdepth 1 -type f -print0 | xargs -0 -I{} -P -n 1 singularity exec\
    #        --cleanenv --bind $workDir/mountdata:/data --writable-tmpfs\
    #        $workDir/singularity/proteowizard-pwiz-skyline-i-agree-to-the-vendor-licenses.img\
    #        mywine msconvert {} --outdir $workDir/output_converted

    singularity exec --cleanenv --bind $workDir/mountdata:/data --writable-tmpfs\
            $workDir/singularity/proteowizard-pwiz-skyline-i-agree-to-the-vendor-licenses.img\
            mywine msconvert $input_file\
            --32 --zlib --filter "peakPicking true 1-" --filter "zeroSamples removeExtra" --outdir $workDir/output_converted
    """
}
