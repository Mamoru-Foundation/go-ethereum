#!/bin/bash

# ./prune.sh container_name

# Define the Geth data directory path
data_dir="<path>"


# Stop the running Geth node
geth_pid=$(pgrep geth)
if [[ -n "$geth_pid" ]]; then
    echo "Stopping Geth node (PID: $geth_pid)..."
    kill -SIGINT $geth_pid
    sleep 15
fi

echo "Executing snapshot prune-state command..."
sudo geth --datadir "$data_dir" snapshot prune-state

echo "Starting Geth node..."
geth --datadir "$data_dir"  &

echo "Geth node started successfully."

