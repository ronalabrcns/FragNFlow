#!/bin/bash
#============================================================
# Script: database.sh 
# Goal: Script to fetch, download and manipulate reference
#       proteome fasta file.
# Used by: database.nf
# Parameters: global params used from database.nf
#============================================================


    echo $input_fasta

    # Check if the input is a Uniprot ID or a FASTA file
    if [[ ! -f "$input_fasta" ]]; then
        echo "Input is a Uniprot ID, downloading FASTA..."
        

        philosopher workspace --init
        philosopher database --id $input_fasta --prefix $decoy_tag --contam
        philosopher workspace --clean
        
        mv *.fas reference_proteome_decoy.fasta
    
    else
        echo Checking decoys in $input_fasta
       
        if grep -q $decoy_tag $input_fasta; then
            cat $input_fasta > reference_proteome_decoy.fasta
            echo "Decoys found in the fasta file, proceeding"
        else
            echo "Decoys not found in the fasta file, adding decoys"

            cp $input_fasta reference_proteome.fasta
            #cd reference_proteome.fasta
            philosopher workspace --init
            philosopher database --custom reference_proteome.fasta --prefix $decoy_tag --contam
            philosopher workspace --clean

            mv *.fas reference_proteome_decoy.fasta
        fi
    fi