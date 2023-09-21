
if [ ! -e "/app/data/backup_list.txt" ]; then
    touch "/app/data/backup_list.txt"
fi

# Check if backup_log.txt exists, and if not, create it
if [ ! -e "/app/data/backup_log.txt" ]; then
    touch "/app/data/backup_log.txt"
fi

# Check if backup_info.json exists, and if not, create it with an empty JSON object
if [ ! -e "/app/data/backup_info.json" ]; then
    echo "{}" > "/app/data/backup_info.json"
fi



#!/bin/bash
welcome_message() {
    echo "***********************"
    echo "Welcome to your SMART backup utility"
    echo -e "1. Full Backup\n2. Incremental Backup\n3. Configure backup list\n4. Schedule a backup"
    echo -n "Enter your preferred option: "
    read option
}

validate_and_append() {
    local user_input="$1"

    if [ -z "$user_input" ]; then
        echo "Input is empty. Please provide a valid path."
        exit 1
    fi


    user_input="$(echo "$user_input" | sed 's/\\/\//g')"
    
    # Check if the specified path exists within the container
    if [ ! -e "/app/data/$user_input" ]; then
        echo "The specified path does not exist within the container. Please provide a valid path."
        exit 1
    fi

    # Check if the specified path is readable within the container
    #if [ ! -r " /app/data/$user_input" ]; then
        #echo "Permission denied. You do not have read access to the specified path."
        #exit 1
    #fi

    # Check if the path already exists in the backup list
    if grep -Fxq "$user_input" /app/data/backup_list.txt; then
        echo "The specified path is already in the backup list."
    else
        echo "$user_input" >> /app/data/backup_list.txt
        echo "Path added to the backup list."
    fi
}

main() {
    welcome_message

    case "$option" in
        1)
            source /app/full.sh
            if [ $? -eq 0 ]; then
		echo "Backup successful"
		source /app/backup.sh
	    else
		echo "$(date) -Backup failed"
	    fi
	    
            ;;
        2)
            source /app/incremental.sh
            if [ $? -eq 0 ]; then
		echo "Backup successful"
		source /app/backup.sh
	    else
		echo "$(date) -Incremental Backup failed"
	    fi
	    
            
            ;;
        3)
            echo "Please enter a file or directory path:"
            read user_input
            validate_and_append "$user_input"
            if [ $? -eq 0 ]; then
		source /app/backup.sh
	    else
		echo "$(date) -Backup failed"
	    fi
	    
            ;;
        4)
            source /app/schedule.sh
            echo "premature termination"
            if [ $? -eq 0 ]; then
		source /app/backup.sh
	    else
		exit 1
	    fi
	    
            ;;
        *)
            echo "Invalid option. Exiting..."
            exit 1
            ;;
    esac
}

main

