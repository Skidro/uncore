#!/bin/bash

# Import the helper functions for using the LLC-slice utilization counters
. ./slice.sh

program_counters
enable_counters

echo 
echo "Running bandwidth benchmark..."
echo
./bandwidth -c 0 -m 16384 -t 3 &> /dev/null

freeze_counters
print_counters
