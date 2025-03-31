#!/bin/bash
database_dir=$launchDir/data/database

    echo $input_fasta

    if [[ ! -f "$input_fasta" ]]; then
        echo "Input is a Uniprot ID, downloading FASTA..."
        
        if [ ! -d \$database_dir ]; then
                mkdir -p \$database_dir
        fi
        # Download the Uniprot FASTA file
        cd \$database_dir
        philosopher workspace --init
        philosopher database --id $input_fasta --prefix $decoy_tag --contam
        philosopher workspace --clean
        
        mv *.fas reference_proteome_decoy.fasta
    
    else
        echo Checking decoys in $input_fasta
        if grep -q $decoy_tag $input_fasta; then
            cat $input_fasta > \$database_dir/reference_proteome_decoy.fasta
            echo "Decoys found in the fasta file, proceeding"
        else
            echo "Decoys not found in the fasta file, adding decoys"
            
            if [ ! -d \$database_dir ]; then
                mkdir -p \$database_dir
            fi
            cp $input_fasta \$database_dir/reference_proteome.fasta
            cd \$database_dir
            philosopher workspace --init
            philosopher database --custom \$database_dir/reference_proteome.fasta --prefix $decoy_tag --contam
            philosopher workspace --clean

            mv *.fas reference_proteome_decoy.fasta
        fi
    fi