# Scripts

A collection of utility and automation scripts. Each script is organized into its own dedicated directory containing the executable script and its assets.

---

## Directory Structure

```text
scripts/
├── auto-cp-to-txt/
│   └── auto-cp-folder.sh
├── text-search/
│   ├── all_text_search.py
│   └── pdf_search.py
├── wallpaper-taskbar-rescaler/
│   └── wallpaper_taskbar_rescaler.py
└── README.md
```

---

## Available Scripts

### 1. auto-cp-to-txt

Recursively scans a target directory and compiles source code into clean text within an `outputs/` directory. Optimized for preparing structured context from a codebase for LLM prompts.

#### Features
- **Automatic Filtering**: Ignores common dependency and cache folders (`node_modules`, `.git`, `venv`, `build`, `dist`, lockfiles) and image files.
- **Line & File Truncation**: Truncates lines exceeding 260 characters and truncates files exceeding 499 lines (retains head and tail).
- **File Rotation**: Automatically splits the auto-cp into indexed files if the output exceeds 3,500 lines.
- **Dual Execution Mode**: Supports both an interactive wizard (with an optional Windows GUI folder picker) and non-interactive command-line arguments.

#### Requirements
- **Bash** environment (Git Bash on Windows, Linux, or macOS).
- **PowerShell** (optional, used by Git Bash on Windows to display the GUI folder picker dialog).

#### Usage Instructions

1. Navigate to the script directory:
   ```bash
   cd auto-cp-to-txt
   ```

2. Ensure the script has execute permissions:
   ```bash
   chmod +x auto-cp-folder.sh
   ```

3. **Interactive Mode**:
   Run without parameters to start the step-by-step prompt:
   ```bash
   ./auto-cp-folder.sh
   ```

4. **CLI Arguments Mode**:
   Run directly with target paths and filters:
   ```bash
   ./auto-cp-folder.sh <source_folder> <output_name> [include_terms...] [*] [exclude_terms...]
   ```

**Command-Line Examples:**
```bash
# auto-cp entire project
./auto-cp-folder.sh /c/projects/my-app my_app_auto-cp

# Include only Python and Markdown files
./auto-cp-folder.sh /c/projects/my-app my_app_auto-cp .py .md

# Include 'src' directory, but exclude 'test' files (separated by '*')
./auto-cp-folder.sh /c/projects/my-app my_app_auto-cp src * test spec
```

All generated texts are saved automatically into `outputs/`.

---

### 2. text-search

CLI tools for searching text occurrences inside documents within a target directory. Results are aggregated and sorted by match frequency in descending order.

#### Scripts
- **`all_text_search.py`**: Searches across both `.pdf` and `.txt` files.
- **`pdf_search.py`**: Dedicated search tool optimized specifically for `.pdf` files.

#### Features
- **Frequency Ranking**: Counts total occurrences of the search term per file and displays highest matches first.
- **Output Flexibility**: Supports printing directly to standard output or exporting results to a UTF-8 text file.
- **Formatted Display**: Truncates long filenames to preserve clean tabular alignment in terminal outputs.

#### Requirements
- Python 3.x
- **PyMuPDF** (`fitz`) library for PDF text extraction:
  ```bash
  pip install PyMuPDF

#### Usage Instructions
- Navigate to the directory:
```bash
cd text-search
```

- Run the script with the required arguments:
```bash
python all_text_search.py <path> <mode> "<search_term>"
python pdf_search.py <path> <mode> "<search_term>"
```

- Arguments:
  - `<path>`: The path to the directory containing the documents.
  - `<mode>`: Output target.
    - `<print>`: Displays output directly in the console.
    - `<text>`: Saves output to a .txt file in the current working directory.
  - `"<search_term>"`: Word or phrase to search for (case-insensitive).

- Examples:
```bash
# Print occurrences of 'invoice' in both PDFs and TXT files
python all_text_search.py /c/documents/reports print "invoice"

# Export occurrences of 'machine learning' in PDFs to a text file
python pdf_search.py /c/documents/papers txt "machine learning"
```

## Adding New Scripts

1. Create a new directory for the script: `mkdir <script-name>`
2. Place the script file inside.
3. Add a description, parameter list, and usage examples to this `README.md`.
