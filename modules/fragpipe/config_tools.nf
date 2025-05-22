#!/usr/bin/env nextflow
nextflow.enable.dsl=2 

process CHECK_DEPENDENCY{
    input:
        val ion
        val msfragger
        val diatracer
        val diann
    output:
        val true
    script:
    """
    echo $ion
    echo $msfragger
    echo $diatracer
    echo $diann
    """
}

process AUTHENTICATE{

    input:
        val first_name
        val last_name
        val email
        val institution
        val license

    output:
        val true
    script:
        """
        NEWEST_VERSION=\$(curl https://msfragger-upgrader.nesvilab.org/upgrader/latest_version.php)

            curl --location --request POST 'https://msfragger-upgrader.nesvilab.org/upgrader/upgrade_download.php'\
                --form 'transfer="academic"'\
                --form 'agreement2="$license"'\
                --form 'agreement3="$license"'\
                --form 'first_name="$first_name"'\
                --form 'last_name="$last_name"'\
                --form 'email="$email"'\
                --form 'organization="$institution"'\
                --form "download=\${NEWEST_VERSION}\\\$zip"\
                --form 'is_fragpipe="true"' 

        """
}

process IONQUANT_DOWNLOAD{
    publishDir "${projectDir}/config_tools", mode: 'move'

    input:
        val ionquant
        val token
        val update

    output:
        path 'ionquant'
    script:
        """
        if [[ $ionquant == false || $update == true ]]; then
            echo "Downloading IonQuant"
            NEWEST_VERSION=\$(curl https://msfragger-upgrader.nesvilab.org/ionquant/latest_version.php)
            curl --output ionquant.zip \
                    "https://msfragger-upgrader.nesvilab.org/ionquant/download.php?token=$token&download=\${NEWEST_VERSION}%24zip"
        
            unzip ionquant.zip
            mv IonQuant* ionquant
        else
            echo "IonQuant already exists"
            cp $projectDir/config_tools/ionquant ionquant
        fi
        """
}

process MSFRAGGER_DOWNLOAD{
    publishDir "${projectDir}/config_tools", mode: 'move'

    input:
        val msfragger
        val token
        val update

    output:
        path 'msfragger'

    script:
        """
        if [[ $msfragger == false || $update == true ]]; then
            # download msfragger
            NEWEST_VERSION=\$(curl https://msfragger-upgrader.nesvilab.org/upgrader/latest_version.php)

            UNI_NEWEST_VERSION=\${NEWEST_VERSION// /%20}

            curl --output msfragger.zip "https://msfragger-upgrader.nesvilab.org/upgrader/download.php?token=$token&download=\${UNI_NEWEST_VERSION}%24zip"\

            unzip msfragger.zip
            mv MSFragger* msfragger
        else
            echo "MSFragger already exists"
            cp -r $projectDir/config_tools/msfragger msfragger
        fi
        """
}

process DIATRACER_DOWNLOAD{
    publishDir "${projectDir}/config_tools", mode: 'move'

    input:
        val diatracer
        val token
        val update

    output:
        path 'diatracer'

    script:
        """
        echo $diatracer
        if [[ ($diatracer == "false" || $update == "true") ]]; then
            # download diatracer
            NEWEST_VERSION=\$(curl https://msfragger-upgrader.nesvilab.org/diatracer/latest_version.php)
            curl --output diatracer.zip "https://msfragger-upgrader.nesvilab.org/diatracer/download.php?token=$token&download=\${NEWEST_VERSION}%24zip"
            
            unzip diatracer.zip
            mv diaTracer* diatracer
        else
            echo "Diatracer already exists"
            cp $projectDir/config_tools/diatracer diatracer
        fi
        """
}

process DIANN_DOWNLOAD{
    publishDir "${projectDir}/config_tools", mode: 'move'

    input:
        val diann
        val link
        val update

    output:
        path 'diann'
    """
    # download DIA-NN
    if [[ ($diann == false || $update == true) && -n $link ]]; then
        echo "Downloading DIA-NN"
        wget $link -O diann.zip
        unzip diann.zip -d diann
        mv diann/diann-* diann/diann
        chmod 755 diann/diann/diann-linux
    else
        echo "DIA-NN already exists"
        mv $projectDir/config_tools/diann diann
    fi
    """
}