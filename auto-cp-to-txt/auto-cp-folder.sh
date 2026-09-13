#!/bin/bash

# Maximum lines allowed per file before truncation
MAX_LINES_PER_FILE=499

# Maximum characters per line (lines longer than this get cut)
MAX_CHARS_PER_LINE=260

MAX_TOTAL_LINES_PER_OUTPUT=3500

INCLUDE_TERMS=()
EXCLUDE_TERMS=()

# --- INTERACTIVE MODE ---
if [ "$#" -eq 0 ]; then

    # move to the script's directory
    cd "$(dirname "$0")" || exit

    # start interacting with the user
    echo "Hi there!"

    #--- Ask user for folder path ---
    while true; do
        read -r -p "Do you want to write folder path or select it? type w for write or s for select (w/s): " CHOOSE_MODE
        
        # Choice: Write manually
        if [[ "$CHOOSE_MODE" =~ ^[Ww]$ ]]; then
            read -r -p "Write or paste here the folder destination you wanna run over: " SOURCE_DIR
            break
            
        # Choice: Select via GUI
        elif [[ "$CHOOSE_MODE" =~ ^[Ss]$ ]]; then
            echo "Opening folder selection window..."
            SOURCE_DIR=$(powershell.exe -NoProfile -Command "
                Add-Type -AssemblyName System.Windows.Forms
                \$f = New-Object System.Windows.Forms.FolderBrowserDialog
                \$f.Description = 'Select the folder destination you wanna run over'
                if (\$f.ShowDialog() -eq 'OK') {
                    Write-Output \$f.SelectedPath
                }
            ")
            
            if [ -z "$SOURCE_DIR" ]; then
                echo "No folder selected. Exiting."
                exit 1
            fi
            break
            
        # Invalid input
        else
            echo "Invalid option. Please type 'w' or 's'."
        fi
    done
    
    # Convert Windows backslashes (\) to forward slashes (/) for Git Bash compatibility
    SOURCE_DIR="${SOURCE_DIR//\\//}"
    echo "You chose this folder: \"$SOURCE_DIR\""
    echo ""
    
    read -r -p "Write the output file name here it adds .txt automatically at the end of the name: " OUT_NAME
    ORIGINAL_OUTPUT_FILE="${OUT_NAME}.txt"
    
    read -r -p "Do you want to copy only some specific files y/n? " ASK_INCLUDE
    if [[ "$ASK_INCLUDE" =~ ^[Yy]$ ]]; then
        read -r -p "Write the included terms here with space between terms: " -a INCLUDE_TERMS
    fi
    
    read -r -p "Do you want to exclude some terms y/n? " ASK_EXCLUDE
    if [[ "$ASK_EXCLUDE" =~ ^[Yy]$ ]]; then
        read -r -p "Write the excluded terms here with space between terms: " -a EXCLUDE_TERMS
    fi

# --- CLI ARGUMENTS MODE ---
else
    if [ "$#" -lt 2 ]; then
        echo "Usage: $0 <source_folder> <output_file> [include_terms...] [*] [exclude_terms...]"
        echo "Run without arguments for interactive mode."
        exit 1
    fi

    SOURCE_DIR="$1"
    ORIGINAL_OUTPUT_FILE="$2"
    shift 2

    PARSE_MODE="include"
    for term in "$@"; do
        if [ "$term" == "*" ]; then
            PARSE_MODE="exclude"
        else
            if [ "$PARSE_MODE" == "include" ]; then
                INCLUDE_TERMS+=("$term")
            else
                EXCLUDE_TERMS+=("$term")
            fi
        fi
    done
fi

# --- INIT OUTPUT DIRECTORY & ROTATION VARIABLES ---
OUTPUT_DIR="outputs"
mkdir -p "$OUTPUT_DIR"

FILE_NAME=$(basename "$ORIGINAL_OUTPUT_FILE")
BASENAME="${FILE_NAME%.*}"
EXTENSION="${FILE_NAME##*.}"
if [ "$BASENAME" == "$FILE_NAME" ]; then
    EXTENSION="txt"
fi

CURRENT_OUTPUT_FILE="$OUTPUT_DIR/${BASENAME}.${EXTENSION}"
CHUNK_INDEX=0
# --------------------------------------------------

# Define a list of patterns to ignore by default
IGNORE_PATTERNS=(".git" "node_modules" ".idea" ".vscode" "__pycache__" ".DS_Store" "venv" "build" "dist" "package-lock.json" "coverage" ".venv")

# Clear the first output file
> "$CURRENT_OUTPUT_FILE"
echo "Starting with output file: $CURRENT_OUTPUT_FILE"

# Find files recursively
find "$SOURCE_DIR" -type f | while read -r file; do
    
    # --- SAFETY FILTER START ---

    # Skip image files (case-insensitive check using bash regex)
    if [[ "${file,,}" =~ \.(jpg|jpeg|png|gif|webp|bmp|ico)$ ]]; then
        continue
    fi
    
    SKIP_IGNORED=false
    
    for ignore in "${IGNORE_PATTERNS[@]}"; do
        if [[ "$file" == *"/$ignore/"* ]] || [[ "$file" == *"/$ignore" ]]; then
            
            IS_EXPLICITLY_REQUESTED=false
            
            for ext in "${INCLUDE_TERMS[@]}"; do
                if [ "$ext" == "$ignore" ]; then
                    IS_EXPLICITLY_REQUESTED=true
                    break
                fi
            done
            
            if [ "$IS_EXPLICITLY_REQUESTED" = false ]; then
                SKIP_IGNORED=true
                break
            fi
        fi
    done
    
    if [ "$SKIP_IGNORED" = true ]; then
        continue
    fi
    # --- SAFETY FILTER END ---

    # --- INCLUSION AND EXCLUSION LOGIC ---
    
    # 1. Inclusion phase
    if [ ${#INCLUDE_TERMS[@]} -gt 0 ]; then
        SHOULD_PROCESS=false
        for term in "${INCLUDE_TERMS[@]}"; do
            if [[ "$file" == *"$term"* ]]; then
                SHOULD_PROCESS=true
                break 
            fi
        done
    else
        SHOULD_PROCESS=true
    fi

    # 2. Exclusion phase
    if [ "$SHOULD_PROCESS" = true ] && [ ${#EXCLUDE_TERMS[@]} -gt 0 ]; then
        for term in "${EXCLUDE_TERMS[@]}"; do
            if [[ "$file" == *"$term"* ]]; then
                SHOULD_PROCESS=false
                break 
            fi
        done
    fi
    # ---------------------------------------

    # Write to file if logic allows
    if [ "$SHOULD_PROCESS" = true ]; then

        # --- FILE ROTATION LOGIC START ---
        if [ -f "$CURRENT_OUTPUT_FILE" ]; then
            CURRENT_TOTAL_LINES=$(wc -l < "$CURRENT_OUTPUT_FILE")
        else
            CURRENT_TOTAL_LINES=0
        fi

        if [ "$CURRENT_TOTAL_LINES" -ge "$MAX_TOTAL_LINES_PER_OUTPUT" ]; then
            CHUNK_INDEX=$((CHUNK_INDEX + 1))
            CURRENT_OUTPUT_FILE="$OUTPUT_DIR/${BASENAME}(${CHUNK_INDEX}).${EXTENSION}"
            
            > "$CURRENT_OUTPUT_FILE"
            echo "Limit reached ($MAX_TOTAL_LINES_PER_OUTPUT lines). Switched to new file: $CURRENT_OUTPUT_FILE"
        fi
        # --- FILE ROTATION LOGIC END ---

        echo "Processing: $file -> $CURRENT_OUTPUT_FILE"
        
        # --- PATH CLEANING LOGIC ---
        ROOT_NAME=$(basename "$SOURCE_DIR")
        REL_PATH="${file#$SOURCE_DIR}"
        REL_PATH="${REL_PATH#/}"
        DISPLAY_PATH="$ROOT_NAME/$REL_PATH"
        # --------------------------------

        echo "==========================================" >> "$CURRENT_OUTPUT_FILE"
        echo "NEW FILE STARTS HERE - FILE PATH: $DISPLAY_PATH" >> "$CURRENT_OUTPUT_FILE"
        echo "==========================================" >> "$CURRENT_OUTPUT_FILE"

        TRUNCATE_FILTER="awk -v max=$MAX_CHARS_PER_LINE '{ 
            len = length(\$0)
            if (len > max) {
                half = int(max / 10)
                start_part = substr(\$0, 1, half)
                end_part = substr(\$0, len - half + 1, half)
                hidden = len - (2 * half)
                print start_part \" ... [LINE SNIPPED: \" hidden \" chars hidden] ... \" end_part
            } else { print \$0 } 
        }'"
        
        LINE_COUNT=$(wc -l < "$file")
        
        if [ "$LINE_COUNT" -gt "$MAX_LINES_PER_FILE" ]; then
            SPLIT_LIMIT=$((MAX_LINES_PER_FILE / 6))
            SKIPPED_LINES=$((LINE_COUNT - MAX_LINES_PER_FILE))
            
            head -n "$SPLIT_LIMIT" "$file" | eval "$TRUNCATE_FILTER" >> "$CURRENT_OUTPUT_FILE"
            
            echo "" >> "$CURRENT_OUTPUT_FILE"
            echo "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv" >> "$CURRENT_OUTPUT_FILE"
            echo "... [SNIPPED] File is too long ($LINE_COUNT lines). ..." >> "$CURRENT_OUTPUT_FILE"
            echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^" >> "$CURRENT_OUTPUT_FILE"
            echo "" >> "$CURRENT_OUTPUT_FILE"
            
            tail -n "$SPLIT_LIMIT" "$file" | eval "$TRUNCATE_FILTER" >> "$CURRENT_OUTPUT_FILE"
        else
            cat "$file" | eval "$TRUNCATE_FILTER" >> "$CURRENT_OUTPUT_FILE"
        fi
        
        echo "==========================================" >> "$CURRENT_OUTPUT_FILE"
        echo "END OF FILE: $(basename "$file")" >> "$CURRENT_OUTPUT_FILE"
        echo "==========================================" >> "$CURRENT_OUTPUT_FILE"
        echo "" >> "$CURRENT_OUTPUT_FILE"
        echo "" >> "$CURRENT_OUTPUT_FILE"

    fi
done

echo "---------------------------------------------------"
echo "Done! The following files were created:"
ls -1 "$OUTPUT_DIR/${BASENAME}"*"${EXTENSION}"
echo "---------------------------------------------------"
echo " "

read -r -p "Press Enter to exit..."