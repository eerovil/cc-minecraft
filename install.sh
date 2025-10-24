#!/bin/bash
# ln -s all of the files and folders here into the path given by user

# Ask user for the path
read -p "Enter the path to the computer's folder: " computer_path

# Create symbolic links for all files in the current directory
for file in *; do
    if [ -f "$file" ]; then
        ln -s "$PWD/$file" "$computer_path/$file"
    fi
done
echo "All files have been linked to $computer_path"

# Also link the lib folder
ln -s "$PWD/lib" "$computer_path/lib"
echo "Lib folder has been linked to $computer_path/lib"