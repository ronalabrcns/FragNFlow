
#input_folder_workflow='/home/rona/sznistvan/FragPipeHPC/TestFP_HPC/test_data/converted_mzML_FXS_test_2/'
#mode="DDA"
# Define list of valid dataTypes (case-insensitive)
valid_data_types=("DDA" "DDA+" "DIA" "DIA-Quant" "DIA-Lib")

input_folder_workflow="${1%/}"  # Remove trailing slash if present

ls $input_folder_workflow

# Loop through all mzML files in the input folder
for file in "$input_folder_workflow"/*; do
    extension="${file##*.}"
    echo $extension

    if [[ "$extension" != "mzML" ]] && [[ "$extension" != "raw" ]]; then
        echo "Skipping file $file (not an mzML or raw file)"
        continue
    fi
    
    filename=$(basename $file)
    filename_no_ext="${filename%.$extension}"

    # Split the filename by underscores into an array
    IFS='_' read -r -a parts <<< "$filename_no_ext"

    # Extract the last part to determine dataType, bioreplicate, or experiment
    last_part="${parts[-1]}"

    if [[ $2 != "TMT" ]]; then

        if [[ ${#parts[@]} -gt 1 ]]; then
            # Check if last_part matches a valid dataType TODO!!
            if [[ "${valid_data_types[@]}" =~ "$last_part" ]]; then
                dataType="$last_part"
                if [[ "${parts[-2]}" =~ ^[0-9]+$ ]]; then
                    # If second-to-last part is a number, it's bioreplicate
                    bioreplicate="${parts[-2]}"
                    if [[ ${#parts[@]} > 3 ]]; then
                        experiment="${parts[-3]}"
                    else
                        # If only two parts, treat the experiment blank
                        experiment=""
                    fi
                else
                    # If second-to-last part is not a number, it's experiment
                    experiment="${parts[-2]}"
                    bioreplicate=""
                fi
            elif [[ "$last_part" =~ ^[0-9] ]]; then
                # If last part is a number, it's bioreplicate
                bioreplicate="$last_part"
                experiment="${parts[-2]}"  # Second-to-last part is experiment
                dataType=""
            else
                # If last part is not a number or valid dataType, it's experiment
                experiment="$last_part"
                bioreplicate=""
                dataType=""
            fi
        else
            experiment=""
            bioreplicate=""
            dataType=""
        fi

        # If experiment is empty, use the second-to-last part if it's not a number (i.e. treat it as experiment)
        if [[ -z "$experiment" ]] && [[ ! "${parts[-2]}" =~ ^[0-9]+$ ]]; then
            experiment="${parts[-2]}"
        fi

        # Extract sample (everything before bioreplicate and experiment)
        #sample="$(echo "${parts[@]:0:${#parts[@]}-3}" | tr ' ' '_')"  # Everything before bioreplicate and experiment

        # Use params.mode if dataType is missing
        dataType="${dataType:-$2}"

        # Ensure we have at least a valid dataType
        if [[ -z "$dataType" ]]; then
            echo "Skipping file $filename (missing required dataType and params.mode is empty)"
            continue
        fi
    else
        # If TMT is specified, set dataType to TMT
        dataType=""
        experiment=""
        bioreplicate=""
    fi
    # Append extracted values to the manifest file (keep correct tab spacing)
    echo -e "$file\t${experiment:-}\t${bioreplicate:-}\t$dataType" >> generated_manifest.fp-manifest
done

echo "Manifest file generated: generated_manifest.fp-manifest"