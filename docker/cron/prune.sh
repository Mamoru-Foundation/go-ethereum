#!/bin/bash

# Define the Geth data directory path
#data_dir="<path>"
#

# Stop the running Geth node
echo "Stopping Geth node ..."
supervisorctl stop geth

echo "Executing snapshot prune-state command..."
supervisorctl start snapshot_prune

echo "Starting Geth node..."
supervisorctl start geth

echo "Geth node started successfully."

