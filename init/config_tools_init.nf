#!/usr/bin/env nextflow
nextflow.enable.dsl=2

def licensingInformation(){
    // Print the licensing information
    println "--------------------- Licensing information ---------------------"
    println file(projectDir + '/init/infos/licensing_information.txt').text
}

def additionMSFraggerLicensingInformationIonQuant(){
    // Print MSFragger licensing information
    println "--------------------- MSFragger licensing information ---------------------"
    println file(projectDir + '/init/infos/msfragger_licensing_information.txt').text
}

def addDownloadInformation(){
    def download_first_name = ''
    def download_last_name = ''
    def download_email = ''
    def download_institution = ''
    def license_accept = false
    def download_tools = false

    // Stdin download information from the user
    ionquant_jar = file(projectDir + '/config_tools/ionquant/').isDirectory()
    msfragger_jar = file(projectDir + '/config_tools/msfragger/').isDirectory()
    diatracer_jar = file(projectDir + '/config_tools/diatracer/').isDirectory()
    diann = file(projectDir + '/config_tools/diann').isDirectory()

    println "--------------------- Tools availability -------------------------"
    println ionquant_jar ? "${GREEN}✅ IonQuant : available" : "${RED}❌ IonQuant : not available"
    println msfragger_jar ? "${GREEN}✅ MSFragger : available" : "${RED}❌ MSFragger : not available"
    println diatracer_jar ? "${GREEN}✅ DiaTracer : available" : "${RED}❌ DiaTracer : not available"
    println diann ? "${GREEN}✅ DIA-NN : available" : "${RED}❌ DIA-NN : not available"
    println "${RESET}\n"

    download_tools = !(ionquant_jar && msfragger_jar && diatracer_jar)

    if (download_tools){
        println "Config tools are not available!\n"
        println "${YELLOW}PLEASE ENTER THE CONTACT INFORMATION TO DOWNLOAD:"
        println "${RESET}First Name:"
        download_first_name = System.in.newReader().readLine()
        println "\nLast Name:"
        download_last_name = System.in.newReader().readLine()
        println "\nEmail:"
        download_email = System.in.newReader().readLine()
        println "\nInstitution:"
        download_institution = System.in.newReader().readLine()

        license_accept = false

        licensingInformation()
        if (System.in.newReader().readLine().toLowerCase().matches("yes|y")){
            license_accept = true
        }
        else{
            license_accept = false
            error "Please accept the licensing information to proceed!"
        }
        
        if (!msfragger_jar){
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
    return [
        ionquant_jar: ionquant_jar,
        msfragger_jar: msfragger_jar,
        diatracer_jar: diatracer_jar,
        diann: diann,
        download_first_name: download_first_name,
        download_last_name: download_last_name,
        download_email: download_email,
        download_institution: download_institution,
        license_accept: license_accept,
        download_tools: download_tools
    ]
}

def token(input){
    def token
    while (true) {
        println "Please enter the authentication code: "
        token = System.in.newReader().readLine()
        if (token ==~ /\d{6}/) {
            break
        } else {
            println "${RED}Invalid input.${RESET} Please enter a 6 digit authentication code."
        }
    }
    println "Token: $token"
    return token
}

def checkEmailForToken()
{
    println "${YELLOW}Please check your email for the authentication code!${RESET}"
}


//***************
//****COLORS*****
//***************
RED = "\u001B[31m"
GREEN = "\u001B[32m"
YELLOW = "\u001B[33m"
CYAN = "\u001B[36m"
RESET = "\u001B[0m"
//***************