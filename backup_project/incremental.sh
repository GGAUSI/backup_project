#!/bin/bash

backup_dir="/app/backups"
log_file="/app/data/backup_log.txt"
backup_list_file="/app/data/backup_list.txt"
backup_info_file="/app/data/backup_info.json"

# Function to convert Windows-style path to Linux-style path
convert_path() {
    local input_path="$1"
    case "$(uname -s)" in
        MINGW* | MSYS* | CYGWIN*) # Windows platform
            echo "$input_path" | sed 's/\\/\//g'
            ;;
        *)
            echo "$input_path" # Linux or other platform, use as is
            ;;
    esac
}

# Check if the backup directory exists
if [ ! -d "$backup_dir" ]; then
    mkdir -p "$backup_dir"
fi

# Declare an associative array to store MD5 checksums
declare -A md5_checksums

# Declare an array to store the paths of files to be included in the tar command
declare -a files_to_backup

# Function to calculate MD5 checksum of a file
calculate_md5() {
    md5sum "$1" | awk '{print $1}'
}

# Read the list of files to be backed up
declare -a paths
while IFS= read -r path; do
    paths+=("$path")
done < "$backup_list_file"

# Check if the previous backup info file exists
if [ -f "$backup_info_file" ]; then
    # Read the previous backup info
    prev_backup_json=$(cat "$backup_info_file")
    
    # Loop through the paths and compare checksums
    for file_path in "${paths[@]}"; do
        path_to_backup="$(convert_path "$file_path")" # Convert path for platform compatibility
        prev_checksum=$(echo "$prev_backup_json" | jq -r ".md5_checksums[\"$path_to_backup\"]")
        current_checksum=$(calculate_md5 "$path_to_backup")
        
        if [ "$prev_checksum" != "$current_checksum" ]; then
            # File has changed since the last backup
            md5_checksums["$path_to_backup"]="$current_checksum"
            files_to_backup+=("$path_to_backup")  # Add the file to the list to be backed up
        else
            # File hasn't changed, retain the previous checksum
            md5_checksums["$path_to_backup"]="$prev_checksum"
        fi
    done
else
    # If there is no previous backup info file (i.e., during the first backup), we initially back up all files listed in the backup_list.txt file.
    files_to_backup=("${paths[@]}")
fi

# Check if there are files to back up
if [ ${#files_to_backup[@]} -eq 0 ]; then
    # No files have changed, log the message and skip the backup
    echo "$(date) - No files have changed. No backup occurred." >> "$log_file"
else
    # Create a backup filename
    backup_filename="backup_$(date +\%Y_\%m_\%d_\%H_\%M_\%S).tar.gz"

    # Perform the incremental backup using tar for files in the list to be backed up
    tar -czf "$backup_dir/$backup_filename" -C / "${files_to_backup[@]}"

    # Create a JSON-formatted string
    backup_json="{"
    backup_json+="\"timestamp\":\"$(date)\","
    backup_json+="\"backup_filename\":\"$backup_filename\","
    backup_json+="\"paths\":["
    for ((i=0; i<${#paths[@]}; i++)); do
        path_to_backup="$(convert_path "${paths[i]}")" # Convert path for platform compatibility
        backup_json+="\"$path_to_backup\""
        if [ $i -lt $((${#paths[@]}-1)) ]; then
            backup_json+=","
        fi
    done
    backup_json+="],"

    # Add MD5 checksums to JSON
    backup_json+="\"md5_checksums\":{"
    for path in "${!md5_checksums[@]}"; do
        backup_json+="\"$path\":\"${md5_checksums[$path]}\","
    done
    # Remove the trailing comma
    backup_json="${backup_json%,}"
    backup_json+="}}"

    # Save the JSON data to the backup_info.json file
    echo "$backup_json" > "$backup_info_file"

    # Check if the backup was successful
    if [ $? -eq 0 ]; then
        echo "$(date)" >> "$log_file"
        echo "$backup_filename" >> "$log_file"
        for file in "${files_to_backup[@]}"; do
            echo "- $file" >> "$log_file"
        done
    else
        echo "$(date) - Backup failed" >> "$log_file"
    fi
fi

