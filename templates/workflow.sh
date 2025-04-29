#!/bin/bash

#============================================================
# Script: workflow.sh 
# Goal: Script to collect the selected workflow from FP container
# Used by: workflow.nf
# Parameters: global params used from workflow.nf (decoy_tag, workflow)
#============================================================

echo "Add database fasta file to selected workflow (inside container)"

fp_version=\$(ls /fragpipe_bin/ | grep fragPipe | cut -d'-' -f2)

ls /fragpipe_bin/fragPipe-\$fp_version/fragpipe/workflows/

echo $launchDir

# Generate selected workflow with the downloaded database
echo "#Adding database fasta file to the selected workflow" > selected_workflow_db.workflow
echo "database.db-path=$launchDir/data/database/reference_proteome_decoy.fasta" >> selected_workflow_db.workflow

cat /fragpipe_bin/fragPipe-\$fp_version/fragpipe/workflows/${workflow}.workflow >> selected_workflow_db.workflow

sed -i "s/^database.decoy-tag=.*/database.decoy-tag=$decoy_tag/" selected_workflow_db.workflow

# ------------------------o------------------------
# Generate a base workflow with only DIA-NN part enabled
# Necessary for newer versions of DIA-NN
echo "#Adding database fasta file to the selected workflow" > diann.workflow
echo "database.db-path=$launchDir/data/database/reference_proteome_decoy.fasta" >> diann.workflow
cat /fragpipe_bin/fragPipe-\$fp_version/fragpipe/workflows/${workflow}.workflow >> diann.workflow

sed -i "s/^msfragger.run-msfragger=true/msfragger.run-msfragger=false/" diann.workflow
sed -i "s/^run-validation-tab=true/run-validation-tab=false/" diann.workflow
sed -i "s/^speclibgen.run-speclibgen=true/speclibgen.run-speclibgen=false/" diann.workflow

