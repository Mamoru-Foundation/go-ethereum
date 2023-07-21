#!/bin/bash

# Define the container name
container_name="$1"

# Get the image name from docker inspect
image=$(docker inspect -f '{{.Config.Image}}' $container_name)
# Get the volume name and mount folder from docker inspect
volume_name=$(docker inspect -f '{{range .Mounts}}{{if eq .Type "volume"}}{{.Name}}{{end}}{{end}}' "$container_name")
mount_folder=$(docker inspect -f '{{range .Mounts}}{{if eq .Type "volume"}}{{.Destination}}{{end}}{{end}}' "$container_name")
# Get the device
device=$(docker volume inspect -f '{{.Options.device}}' "$volume_name")


# Check if volume_name is not empty and Type is "volume"
if [ -n "$volume_name" ] && [ -n "$mount_folder" ]; then
  echo "Stopping container: $container_name"
  docker stop $container_name

  echo "Running snapshot prune-state container..."
  docker run --rm -v "$device":"$mount_folder" --entrypoint geth  "$image" --datadir /data/data/ snapshot prune-state

  # Start the Geth container again
  echo "Starting container: $container_name"
  docker start $container_name

  echo "Container sequence completed."
else
    echo "Error: No volume found for container '$container_name'."
fi


