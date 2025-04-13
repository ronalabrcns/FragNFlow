#!/usr/bin/env nextflow
nextflow.enable.dsl=2 

process COLLECT_FP_ANALYST_FILES{
    publishDir "output/fp_analyst", mode: 'move'

    input:
        path output_folder_fragpipe
        val mode
        val analyst_mode

    output:
        path 'experiment_annotation.tsv'
        path 'p_table.tsv'

    script:
    """
    echo $output_folder_fragpipe
    echo $mode

    out_fp_dir=$launchDir/output/fragpipe/$output_folder_fragpipe
    echo \$out_fp_dir

    cat \$out_fp_dir/experiment_annotation.tsv > experiment_annotation.tsv
    if [[ $mode == "DDA" ]]; then
        if [[ $analyst_mode == "peptide" ]]; then
            cat \$out_fp_dir/combined_peptide.tsv > p_table.tsv
        else
            cat \$out_fp_dir/combined_protein.tsv > p_table.tsv
        fi
    elif [[ $mode == "TMT" ]]; then
        #TODO "experiment_annotation.tsv"
        if [[ $analyst_mode == "peptide" ]]; then
            cat \$out_fp_dir/abundance_peptide_MD.tsv > p_table.tsv
        else
            cat \$out_fp_dir/abundance_gene_MD.tsv > p_table.tsv
        fi
    elif [[ $mode == "DIA" ]]; then
        if [[ $analyst_mode == "peptide" ]]; then
            cat \$out_fp_dir/diann-output/report.pr_matrix.tsv > p_table.tsv
        else
            cat \$out_fp_dir/diann-output/report.pg_matrix.tsv > p_table.tsv
        fi
    fi
    """   
}

process FP_ANALYST{
    publishDir "output", mode: 'copy'
    
    container 'sznistvan/fp-anal-hpc:latest'
    //containerOptions '--cleanenv --bind $HOME/.config,$p_table_folder:/folder --writable-tmpfs'

    input:
        val experiment_annotation
        val protein_table
        val experiment_folder
        val p_table_folder
        val mode
        val gene_list
        val plot_mode
        val analyst_mode
        val go_database

    output:
        path 'fp_analyst'

    script:
    """
    mkdir fp_analyst
    echo \${PWD}
    selected_mode=$mode
    if [[ \$selected_mode == "DDA" ]]; then
        selected_mode="LFQ"
    fi
    head $protein_table
    Rscript $projectDir/templates/fp_analyst.r $projectDir \
                                            $experiment_annotation \
                                            $protein_table \
                                            \$selected_mode \
                                            '${gene_list.join(",")}' \
                                            $plot_mode \
                                            fp_analyst \
                                            \${PWD} \
                                            $go_database
    """

    //Ez mukodik: singularity exec --cleanenv --bind /home/rona/sznistvan/Nextflow/nf-fphpc/data/singularity/test:/test fp-analyst-test.sif Rscript test/rtest.r
}