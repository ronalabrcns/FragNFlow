#!/bin/bash
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
# Generate a base workflow with only DIANN enabled
echo "#Adding database fasta file to the selected workflow" > diann.workflow
echo "database.db-path=$launchDir/data/database/reference_proteome_decoy.fasta" >> diann.workflow
cat /fragpipe_bin/fragPipe-\$fp_version/fragpipe/workflows/${workflow}.workflow >> diann.workflow

sed -i "s/^msfragger.run-msfragger=true/msfragger.run-msfragger=false/" diann.workflow
sed -i "s/^run-validation-tab=true/run-validation-tab=false/" diann.workflow
sed -i "s/^speclibgen.run-speclibgen=true/speclibgen.run-speclibgen=false/" diann.workflow


# sed -i "s/^msbooster.run-msbooster=true/msbooster.run-msbooster=false/" diann.workflow
# sed -i "s/^run-psm-validation=true/run-psm-validation=false/" diann.workflow
# sed -i "s/^percolator.run-percolator=true/percolator.run-percolator=false/" diann.workflow
# sed -i "s/^protein-prophet.run-protein-prophet=true/protein-prophet.run-protein-prophet=false/" diann.workflow
# sed -i "s/^phi-report.run-report=true/phi-report.run-report=false/" diann.workflow
# sed -i "s/^ionquant.run-ionquant=true/ionquant.run-ionquant=false/" diann.workflow
# sed -i "s/^speclibgen.run-speclibgen=true/speclibgen.run-speclibgen=false/" diann.workflow
