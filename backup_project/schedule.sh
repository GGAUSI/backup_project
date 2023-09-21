#!/bin/bash

# Function to validate and set the cron schedule
set_cron_schedule() {
  local frequency="$1"
  local minute="$2"
  local hour="$3"
  local day="$4"

  case "$frequency" in
    daily)
      cron_schedule="$minute $hour * * *"
      ;;
    weekly)
      cron_schedule="$minute $hour * * $day"
      ;;
    monthly)
      cron_schedule="$minute $hour $day * *"
      ;;
    *)
      echo "Invalid frequency: $frequency"
      exit 1
      ;;
  esac
}

# Prompt the user for the backup frequency
read -p "Choose backup frequency (daily/weekly/monthly): " backup_frequency

# Validate the backup frequency input and set additional parameters
case "$backup_frequency" in
  daily)
    read -p "Enter the minute to run the cron job (0-59): " cron_minute
    if ! [[ $cron_minute =~ ^[0-5]?[0-9]$ ]]; then
      echo "Error: Invalid minute format (0-59)."
      exit 1
    fi
    read -p "Enter the hour to run the cron job (0-23): " cron_hour
    if ! [[ $cron_hour =~ ^[0-2]?[0-9]$ ]]; then
      echo "Error: Invalid hour format (0-23)."
      exit 1
    fi
    set_cron_schedule "daily" "$cron_minute" "$cron_hour"
    ;;
  weekly)
    read -p "Enter the minute to run the cron job (0-59): " cron_minute
    if ! [[ $cron_minute =~ ^[0-5]?[0-9]$ ]]; then
      echo "Error: Invalid minute format (0-59)."
      exit 1
    fi
    read -p "Enter the hour to run the cron job (0-23): " cron_hour
    if ! [[ $cron_hour =~ ^[0-2]?[0-9]$ ]]; then
      echo "Error: Invalid hour format (0-23)."
      exit 1
    fi
    read -p "Enter the day of the week to run the cron job (0-6, where 0 is Sunday): " cron_day
    if ! [[ $cron_day =~ ^[0-6]$ ]]; then
      echo "Error: Invalid day of the week (0-6)."
      exit 1
    fi
    set_cron_schedule "weekly" "$cron_minute" "$cron_hour" "$cron_day"
    ;;
  monthly)
    read -p "Enter the minute to run the cron job (0-59): " cron_minute
    if ! [[ $cron_minute =~ ^[0-5]?[0-9]$ ]]; then
      echo "Error: Invalid minute format (0-59)."
      exit 1
    fi
    read -p "Enter the hour to run the cron job (0-23): " cron_hour
    if ! [[ $cron_hour =~ ^[0-2]?[0-9]$ ]]; then
      echo "Error: Invalid hour format (0-23)."
      exit 1
    fi
    read -p "Enter the day of the month to run the cron job (1-31): " cron_day
    if ! [[ $cron_day =~ ^([1-9]|[12][0-9]|3[01])$ ]]; then
      echo "Error: Invalid day of the month (1-31)."
     
      exit 1
    fi
    set_cron_schedule "monthly" "$cron_minute" "$cron_hour" "$cron_day"
    ;;
  *)
    echo "Error: Invalid backup frequency. Choose 'daily', 'weekly', or 'monthly'."
    exit 1
    ;;
esac

# Add the cron job to the user's crontab
(crontab -l 2>/dev/null; echo "$cron_schedule /app/incremental.sh") | crontab -
echo "Cron job added successfully."

exit 0


