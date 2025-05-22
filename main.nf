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

def licensingInformation(){
    // Print the licensing information
    println file(projectDir + '/modules/fragpipe/infos/licensing_information.txt').text
}

def additionMSFraggerLicensingInformationIonQuant(){
    // Print MSFragger licensing information
    println file(projectDir + '/modules/fragpipe/infos/msfragger_licensing_information.txt').text 
}

def addDownloadInformation(){
    // Stdin download information from the user
    def configToolsDir = new File(projectDir.toFile(), 'config_tools')

    ionquant_jar = file(projectDir + '/config_tools/ionquant/').isDirectory()
    msfragger_jar = file(projectDir + '/config_tools/msfragger/').isDirectory()
    diatracer_jar = file(projectDir + '/config_tools/diatracer/').isDirectory()
    diann = file(projectDir + '/config_tools/diann').isDirectory()

    println ionquant_jar ? "${GREEN}IonQuant is available" : "${RED}IonQuant is not available"
    println msfragger_jar ? "${GREEN}MSFragger is available" : "${RED}MSFragger is not available"
    println diatracer_jar ? "${GREEN}DiaTracer is available" : "${RED}DiaTracer is not available"
    println diann ? "${GREEN}DIA-NN is available" : "${RED}DIA-NN is not available"

    if (!ionquant_jar || !msfragger_jar || !diatracer_jar || params.config_tools_update){
        println "Config tools are not available (IonQuant, MSFragger, DiaTracer)."
        println "PLEASE ENTER THE CONTACT INFORMATION TO DOWNLOAD:"
        println "First Name:"
        download_first_name = System.in.newReader().readLine()
        println "Last Name:"
        download_last_name = System.in.newReader().readLine()
        println "\nEmail:"
        download_email = System.in.newReader().readLine()
        println "\nInstitution:"
        download_institution = System.in.newReader().readLine()

        licensingInformation()
        if (System.in.newReader().readLine().toLowerCase().matches("yes|y")){
            license_accept = true
        }
        else{
            license_accept = false
            error "Please accept the licensing information to proceed!"
        }
        
        if (!msfragger_jar || params.config_tools_update){
            additionMSFraggerLicensingInformationIonQuant()
            if (System.in.newReader().readLine().toLowerCase().matches("yes|y")){
                license_accept = true
            }
            else{
                license_accept = false
                error "Please accept the licensing information to proceed!"
            }
        }
    }
}

def token(input){
    println "Authentication code:"
    def token = System.in.newReader().readLine()
    println "Token: $token"

    return token
}

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
        first_name
        last_name
        email
        institution
        license

    main:
        AUTHENTICATE(first_name, last_name, email, institution, license)
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
        update

    main:
        //AUTHENTICATE(first_name, last_name, email, institution, license)
        //TODO: add a seprate sub-workflow for the authentication
        // After that we can call the token read input function in the main workflow
        //Continueu with this worklfow with tool downloads!

        IONQUANT_DOWNLOAD(ionquant, token, update)
        MSFRAGGER_DOWNLOAD(msfragger, token, update)
        DIATRACER_DOWNLOAD(diatracer, token, update)
        DIANN_DOWNLOAD(diann, diann_download, update) 

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

        WORKFLOW_DB(DATABASE.out, workflow, decoy_tag)

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

    addDownloadInformation()
    //auth_ch = AUTHENTICATION(download_first_name, download_last_name, download_email, download_institution, license_accept)
    //token_ch = auth_ch.map { it -> token(it) }
    //token_ch.view { token -> "Token: $token" }
    //token_channel = Channel.of(token)
    //CONFIG_TOOLS_WF(token_ch, ionquant_jar, msfragger_jar, diatracer_jar, diann, params.diann_download, params.config_tools_update)

    if (!params.disable_msconvert){
        println "hello"
        MSCONVERTER_WF(raw_file_type, batch_size)
    }
    if (!params.disable_fragpipe){
        //Config Tools
        addDownloadInformation()
        
        auth_ch = AUTHENTICATION(download_first_name, download_last_name, download_email, download_institution, license_accept)
        token_ch = auth_ch.map { it -> token(it) }

        CONFIG_TOOLS_WF(token_ch, ionquant_jar, msfragger_jar, diatracer_jar, diann, params.diann_download, params.config_tools_update)
   
        if (params.disable_msconvert){
            FRAGPIPE_WF(CONFIG_TOOLS_WF.out, input_folder, 
                    mode, workflow, fasta_file, 
                    decoy_tag, threads, ram, params.diann_download, params.analyst_mode)
        }
        else{
            FRAGPIPE_WF(CONFIG_TOOLS_WF.out, MSCONVERTER_WF.out, 
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



//***************
//****CONFIG*****
//***************
ionquant_jar = false
msfragger_jar = false
diatracer_jar = false
diann = false

//***************
//****LICENCE****
//***************
download_first_name = ''
download_last_name = ''
download_email = ''
download_institution = ''
license_accept = false
//token=''

//***************
//****COLORS*****
//***************
RED = "\u001B[31m"
GREEN = "\u001B[32m"
YELLOW = "\u001B[33m"
CYAN = "\u001B[36m"
RESET = "\u001B[0m"