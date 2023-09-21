# Use Ubuntu 20.04 as the base image
FROM ubuntu:20.04

# Install the cron package
RUN apt-get update && apt-get install -y cron

# Set the working directory inside the container
WORKDIR /app

# Create directories with permissions
RUN mkdir -p /app/data && \
    chown 1000:1000 /app/data && \
    chmod 777 /app/data

# Install required packages (bash, tar, jq, and any other dependencies you need)
RUN apt-get update && apt-get install -y bash tar jq

# Add your backup scripts and other necessary files to the container
COPY incremental.sh /app
COPY full.sh /app
COPY backup.sh /app
COPY schedule.sh /app

# Copy files with permissions
COPY --chown=1000:1000 backup_log.txt /app/data
COPY --chown=1000:1000 backup_info.json /app/data
COPY --chown=1000:1000 backup_list.txt /app/data

# Add a cron job file to the container
COPY crontab /etc/cron.d/my-cron-job

# Give execution rights to the cron job file
RUN chmod 0644 /etc/cron.d/my-cron-job

# Apply the cron job
RUN crontab /etc/cron.d/my-cron-job

# Specify a volume mount point where backups will be saved
VOLUME /app/data

# Define the default command to run your backup script
#CMD ["/bin/bash", "-c"]

