#!/usr/bin/env nextflow
nextflow.enable.dsl=2

/*
=========================================================================================
 Frag'n'Flow: Automated Workflow for Large-Scale Quantitative Proteomics in HPC Environments
-----------------------------------------------------------------------------------------
 Description :   Main workflow for executing Frag'n'Flow. Change parameters in the config file.
 Author      :   Istvan Szepesi-Nagy (szepesi-nagy.istvan@ttk.hu)
 Created     :   2024-04-29
 Version     :   v1.0.0
 Repository  :   https://github.com/ronalabrcns/FragNFlow
 License     :   MIT
==========================================================================================
*/

include { MSCONVERTER; MSCONVERTER_FOLDER; CHECK_CONVERT_SUCCESS } from './modules/msconverter/msconverter.nf'
include { MANIFEST } from './modules/headless_setup/annotation.nf'
include { DATABASE } from './modules/headless_setup/database.nf'
include { WORKFLOW_DB } from './modules/headless_setup/workflow.nf'
include { AUTHENTICATE; IONQUANT_DOWNLOAD; MSFRAGGER_DOWNLOAD; DIATRACER_DOWNLOAD; DIANN_DOWNLOAD; CHECK_DEPENDENCY } from './modules/fragpipe/config_tools.nf'
include { FRAGPIPE } from './modules/fragpipe/fragpipe.nf'
include { FP_ANALYST; COLLECT_FP_ANALYST_FILES } from './modules/fp_analyst/fp_analyst.nf'

include { addDownloadInformation; token; checkEmailForToken } from './init/config_tools_init.nf'

// MSConverter sub-workflow
workflow MSCONVERTER_WF{
    take:
        raw_file_type
        batch_size

    main:
        ch_input_file = Channel.fromPath("${params.input_folder}/*.raw").buffer(size:params.batch_size, remainder:true)
        MSCONVERTER(ch_input_file)

        MSCONVERTER.out.flatten().collect().view {c -> "Msconverter output: $c"}

        MSCONVERTER_FOLDER(MSCONVERTER.out.flatten().collect(), params.input_folder)

        MSCONVERTER_FOLDER.out.view{folder -> "The MSconverter output folder path is: $folder"}

    emit:
        MSCONVERTER_FOLDER.out
}

workflow AUTHENTICATION{
    take:
        download_tools
        first_name
        last_name
        email
        institution
        license

    main:
        AUTHENTICATE(download_tools, first_name, last_name, email, institution, license)
        if (download_tools){
            checkEmailForToken()
        }
    emit:
        AUTHENTICATE.out
}

// Config Tools sub-workflow
workflow CONFIG_TOOLS_WF{
    take:
        token
        ionquant
        msfragger
        diatracer
        diann
        diann_download

    main:

        IONQUANT_DOWNLOAD(ionquant, token)
        MSFRAGGER_DOWNLOAD(msfragger, token)
        DIATRACER_DOWNLOAD(diatracer, token)
        DIANN_DOWNLOAD(diann, diann_download)

        CHECK_DEPENDENCY(IONQUANT_DOWNLOAD.out,
                        MSFRAGGER_DOWNLOAD.out,
                        DIATRACER_DOWNLOAD.out, 
                        DIANN_DOWNLOAD.out)
        emit:
            CHECK_DEPENDENCY.out
}
// FragPipe sub-workflow
workflow FRAGPIPE_WF{
    take:
        config_tools
        input_folder
        mode
        workflow
        fasta_file
        decoy_tag
        threads
        ram
        diann_download
        analyst_mode

    main:
        MANIFEST(input_folder, mode)

        DATABASE(fasta_file, decoy_tag)

        WORKFLOW_DB(DATABASE.out[0], workflow, decoy_tag)

        FRAGPIPE(config_tools, MANIFEST.out, WORKFLOW_DB.out[0], WORKFLOW_DB.out[1], ram, threads, mode, diann_download)

        COLLECT_FP_ANALYST_FILES(FRAGPIPE.out, mode, analyst_mode)

    emit:
        COLLECT_FP_ANALYST_FILES.out[0] //as experiment_annotation
        COLLECT_FP_ANALYST_FILES.out[1] //as protein_table
}

// FPAnalyst sub-workflow
workflow FP_ANALYST_WF{
    take:
        experiment
        prot_table
        mode
        gene_list
        plot_mode
        analyst_mode
        go_database

    main:
        FP_ANALYST(experiment, prot_table, mode, gene_list, plot_mode, analyst_mode, go_database)    

}

// Main workflow
workflow {
    input_folder = Channel.of(params.input_folder)
    raw_file_type = Channel.of(params.raw_file_type)
    batch_size = Channel.of(params.batch_size)
    mode = Channel.of(params.mode)
    workflow = Channel.of(params.workflow)
    fasta_file = Channel.fromPath(params.fasta_file)
    decoy_tag = Channel.of(params.decoy_tag)
    threads = Channel.of(params.threads)
    ram = Channel.of(params.ram)

    if (params.config_tools){
        //Config Tools
        //TODO add a disable option for the config tools this way an init install process can be run
        //without the need of running the whole workflow
        infos = addDownloadInformation()

        auth_ch = AUTHENTICATION(infos.download_tools, infos.download_first_name, infos.download_last_name, infos.download_email, infos.download_institution, infos.license_accept)
        token_ch = infos.download_tools ? auth_ch.map { token(it) } : Channel.of('1234')
        CONFIG_TOOLS_WF(token_ch, infos.ionquant_jar, infos.msfragger_jar, infos.diatracer_jar, infos.diann, params.diann_download)
    }
    if (!params.disable_msconvert){
        MSCONVERTER_WF(raw_file_type, batch_size)
    }
    if (!params.disable_fragpipe){

        def config_tools_out = params.config_tools ? CONFIG_TOOLS_WF.out : true

        if (params.disable_msconvert){

            FRAGPIPE_WF(config_tools_out, input_folder,
                    mode, workflow, fasta_file,
                    decoy_tag, threads, ram, params.diann_download, params.analyst_mode)
        }
        else{
            FRAGPIPE_WF(config_tools_out, MSCONVERTER_WF.out,
                        mode, workflow, fasta_file,
                        decoy_tag, threads, ram, params.diann_download, params.analyst_mode)
        }
    }
    if (!params.disable_fp_analyst){
        if (!params.disable_fragpipe){
            FP_ANALYST_WF(FRAGPIPE_WF.out[0], FRAGPIPE_WF.out[1], mode, params.gene_list, params.plot_mode, params.analyst_mode, params.go_database)
        }
        else{
            println file(params.p_table).parent
            FP_ANALYST_WF(params.experiment, params.p_table, mode, params.gene_list, params.plot_mode, params.analyst_mode, params.go_database)
        }    
    }
}