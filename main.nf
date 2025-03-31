#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Parameters these can be fetched into a yaml file later!

include { PULLMSCONVERTER; MSCONVERTER } from './modules/msconverter/msconverter.nf'
include { MANIFEST } from './modules/headless_setup/annotation.nf'
include { DATABASE } from './modules/headless_setup/database.nf'
include { WORKFLOW_DB } from './modules/headless_setup/workflow.nf'
include { IONQUANT_DOWNLOAD; MSFRAGGER_DOWNLOAD; DIATRACER_DOWNLOAD; DIANN_DOWNLOAD; CHECK_DEPENDENCY } from './modules/fragpipe/config_tools.nf'
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
    // Read the download information from the user
    //ionquant_jar = file(projectDir + '/config_tools/IonQuant-?.jar').exists()

    def configToolsDir = new File(projectDir.toFile(), 'config_tools')

    ionquant_jar = configToolsDir.list({ dir, name -> name.startsWith("IonQuant-") && name.endsWith(".jar") })?.length > 0
    msfragger_jar = file(projectDir + '/config_tools/msfragger/').isDirectory()
    diatracer_jar = configToolsDir.list({ dir, name -> name.startsWith("diaTracer-") && name.endsWith(".jar") })?.length > 0
    diann = file(projectDir + '/config_tools/diann').isDirectory()

    println ionquant_jar
    println msfragger_jar
    println diatracer_jar
    println diann

    if (!ionquant_jar || !msfragger_jar || !diatracer_jar || params.config_tools_update){
        println "Config tools are not available (IonQuant, MSFragger, DiaTracer)."
        println "PLEASE ENTER THE CONTACT INFORMATION TO DOWNLOAD:"
        println "Name:"
        download_name = System.in.newReader().readLine()
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

// MSConverter sub-workflow LATER
workflow MSCONVERTER_WF{
    // Define the processes and their order
    PULLMSCONVERTER()
    ch_input_folder = Channel.fromPath('/home/rona/sznistvan/Nextflow/test_msconverter/my_data/*.raw')
    ch_input_folder.view()
    ch_cpus = Channel.of(params.cpus)

    MSCONVERTER(ch_input_folder)
}

// FragPipe sub-workflows
workflow CONFIG_TOOLS_WF{
    take:
        name
        email
        institution
        license
        ionquant
        msfragger
        diatracer
        diann
        diann_download
        update

    main:
        IONQUANT_DOWNLOAD(ionquant, name, email, institution, license, update)
        MSFRAGGER_DOWNLOAD(msfragger, name, email, institution, license, update)
        DIATRACER_DOWNLOAD(diatracer, name, email, institution, license, update)
        DIANN_DOWNLOAD(diann, diann_download, update) 

        CHECK_DEPENDENCY(IONQUANT_DOWNLOAD.out, 
                        MSFRAGGER_DOWNLOAD.out, 
                        DIATRACER_DOWNLOAD.out, 
                        DIANN_DOWNLOAD.out)

    emit:
        CHECK_DEPENDENCY.out
}

workflow FRAGPIPE_WF{
    take:
        config_tools
        input_folder
        output_folder
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

        FRAGPIPE(config_tools, MANIFEST.out, WORKFLOW_DB.out[0], WORKFLOW_DB.out[1], ram, threads, mode, diann_download)   //out out out to wait for all other processes to finish

        COLLECT_FP_ANALYST_FILES(FRAGPIPE.out, mode, analyst_mode)

    emit:
        COLLECT_FP_ANALYST_FILES.out[0] //as experiment_annotation
        COLLECT_FP_ANALYST_FILES.out[1] //as protein_table
}

// FPAnalyst sub-workflow
workflow FP_ANALYST_WF{
    // Define the processes and their order
    take:
        experiment
        prot_table
        mode
        gene_list
        plot_mode

    main:
        FP_ANALYST(experiment, prot_table, mode, gene_list, plot_mode)    

}

// Main workflow
workflow {
    input_folder = Channel.of(params.input_folder)
    output_folder = Channel.fromPath(params.output_folder)
    mode = Channel.of(params.mode)
    workflow = Channel.of(params.workflow)
    fasta_file = Channel.fromPath(params.fasta_file)
    decoy_tag = Channel.of(params.decoy_tag)
    threads = Channel.of(params.threads)
    ram = Channel.of(params.ram)

    //Config Tools
    addDownloadInformation()

    if (!params.disable_msconvert){
        //MSCONVERTER_WF()
        //new input folder
    }
    if (!params.disable_fragpipe){
        CONFIG_TOOLS_WF(download_name, download_email, download_institution, license_accept,
                    ionquant_jar, msfragger_jar, diatracer_jar, diann, params.diann_download, 
                    params.config_tools_update)

        FRAGPIPE_WF(CONFIG_TOOLS_WF.out, input_folder, output_folder, 
                    mode, workflow, fasta_file, 
                    decoy_tag, threads, ram, params.diann_download, params.analyst_mode)
    }
    if (!params.disable_fp_analyst){
        if (!params.disable_fragpipe){
            FP_ANALYST_WF(FRAGPIPE_WF.out[0], FRAGPIPE_WF.out[1], mode, params.gene_list, params.plot_mode, params.analyst_mode)
        }
        else{
            FP_ANALYST_WF(params.experiment, params.prot_table, mode, params.gene_list, params.plot_mode, params.analyst_mode)
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
download_name = ''
download_email = ''
download_institution = ''
license_accept = false