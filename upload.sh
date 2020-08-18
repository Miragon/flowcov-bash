#!/bin/bash
    
# Find all matching files in all subdirs, then output them along with a separating comma
value=$(find . -name 'flowCovReport.json' -print0 | xargs -I{} -0 sh -c '{ cat {}; echo ,; }')

# Remove the last comma by reversing the string, removing the first char, and reversing it again
value=$(echo $value | rev | cut -c 2- | rev)

# Create the json array with the now comma-separated list of reports
value="[$value]"

# Push them to the server
uuid=$(curl -H "Content-Type: application/json" -X POST -d "$value" https://app.flowcov.io/api/v0/run)

# Output the result
echo "Your upload UUID is $uuid"