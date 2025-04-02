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

process IONQUANT_DOWNLOAD{
    publishDir "${projectDir}/config_tools", mode: 'move'

    input:
        val ionquant
        val name
        val email
        val institution
        val license
        val update

    output:
        path 'IonQuant-*.jar'
        //path 'LICENSE_ionquant.pdf'
    script:
        """
        NEWEST_VERSION=\$(curl https://msfragger-upgrader.nesvilab.org/ionquant/latest_version.php)
        if [[ $ionquant == false || $update == true ]]; then
            echo "Downloading IonQuant"

            curl --location --request POST 'https://msfragger-upgrader.nesvilab.org/ionquant/upgrade_download.php' \
                --form 'transfer="academic"' \
                --form 'agreement1="$license"' \
                --form 'name="$name"' \
                --form 'email="$email"' \
                --form 'organization="$institution"' \
                --form "download=\${NEWEST_VERSION}\\\$jar" \
                --output IonQuant-\${NEWEST_VERSION}.jar
        else
            echo "IonQuant already exists"
            cp $projectDir/config_tools/IonQuant-\${NEWEST_VERSION}.jar IonQuant-\${NEWEST_VERSION}.jar
        fi
        """
}

process MSFRAGGER_DOWNLOAD{
    publishDir "${projectDir}/config_tools", mode: 'move'

    input:
        val msfragger
        val name
        val email
        val institution
        val license
        val update

    output:
        //path 'msfragger.zip'
        path 'msfragger'

    script:
        """
        if [[ $msfragger == false || $update == true ]]; then
            # download msfragger
            NEWEST_VERSION=\$(curl https://msfragger-upgrader.nesvilab.org/upgrader/latest_version.php)

            curl --location --request POST 'https://msfragger-upgrader.nesvilab.org/upgrader/upgrade_download.php'\
                --form 'transfer="academic"'\
                --form 'agreement2="$license"'\
                --form 'agreement3="$license"'\
                --form 'name="$name"'\
                --form 'email="$email"'\
                --form 'organization="$institution"'\
                --form "download=\${NEWEST_VERSION}\\\$zip"\
                --output msfragger.zip

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
        val name
        val email
        val institution
        val license
        val update

    output:
        path 'diaTracer-*.jar'
        //path 'LICENSE_diatracer.pdf'

    script:
        """
        NEWEST_VERSION=\$(curl https://msfragger-upgrader.nesvilab.org/diatracer/latest_version.php)
        echo $diatracer
        if [[ ($diatracer == "false" || $update == "true") ]]; then
            # download diatracer
            
            curl --location --request POST 'https://msfragger-upgrader.nesvilab.org/diatracer/upgrade_download.php'\
                --form 'transfer="academic"'\
                --form 'agreement1="$license"'\
                --form 'name="$name"'\
                --form 'email="$email"'\
                --form 'organization="$institution"'\
                --form "download=\${NEWEST_VERSION}\\\$jar"\
                --output diaTracer-\${NEWEST_VERSION}.jar
        else
            echo "Diatracer already exists"
            cp $projectDir/config_tools/diaTracer-\${NEWEST_VERSION}.jar diaTracer-\${NEWEST_VERSION}.jar
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