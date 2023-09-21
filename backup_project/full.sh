#!/bin/bash

backup_dir="/app/data"
backup_filename="backup_$(date +\%Y_\%m_\%d_\%H_\%M_\%S).tar.gz"
log_file="/app/data/backup_log.txt"
backup_list_file="/app/data/backup_list.txt"

echo "$(date) - Cron job executed" >> "$log_file"

mkdir -p "$backup_dir"

declare -a paths
while IFS= read -r path; do
    paths+=("$path")
done < "$backup_list_file"

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

# Perform the full backup using tar
tar -czf "$backup_dir/$backup_filename" -C / "${paths[@]}"

# Create an associative array to store MD5 checksums
declare -A md5_checksums

# Create a JSON-formatted string
backup_json="{"
backup_json+="\"timestamp\":\"$(date)\","
backup_json+="\"backup_filename\":\"$backup_filename\","
backup_json+="\"paths\":["
for ((i=0; i<${#paths[@]}; i++)); do
    path_to_backup="$(convert_path "${paths[i]}")" # Convert path for platform compatibility
    # Calculate MD5 checksum for each file
    md5_checksum=$(md5sum "$path_to_backup" | awk '{print $1}')
    md5_checksums["$path_to_backup"]="$md5_checksum"

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
echo "$backup_json" > "/app/data/backup_info.json"

# Check if the backup was successful
if [ $? -eq 0 ]; then
    echo "$(date)" >> "$log_file"
    echo "$backup_filename" >> "$log_file"
    for path in "${paths[@]}"; do
        echo "- $path" >> "$log_file"
    done
else
    echo "$(date) - Backup failed" >> "$log_file"
fi

