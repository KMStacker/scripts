import os
import sys
import fitz  # PyMuPDF
import argparse

def search_files(directory_path, search_term):
    results = []
    search_term_lower = search_term.lower()

    for filename in os.listdir(directory_path):
        file_path = os.path.join(directory_path, filename)
        match_count = 0
        
        # 1. .pdf files
        if filename.lower().endswith(".pdf"):
            try:
                pdf_document = fitz.open(file_path)
                for page_num in range(pdf_document.page_count):
                    page = pdf_document.load_page(page_num)
                    text = page.get_text("text").lower()
                    match_count += text.count(search_term_lower)
                
                pdf_document.close()
                results.append((match_count, filename))
                
            except Exception as e:
                print(f"Error reading PDF {filename}: {e}")

        # 2. .txt files
        elif filename.lower().endswith(".txt"):
            try:
                with open(file_path, "r", encoding="utf-8") as file:
                    text = file.read().lower()
                    match_count = text.count(search_term_lower)
                
                results.append((match_count, filename))
                
            except Exception as e:
                print(f"Error reading TXT {filename}: {e}")

    # srt results
    results.sort(key=lambda x: x[0], reverse=True)
    return results

def truncate_filename(filename, max_length):
    if len(filename) > max_length:
        return filename[:max_length - 3] + "..."
    return filename

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Search PDFs and TXT files.")
    parser.add_argument("path", help="Path to the folder containing files")
    parser.add_argument("mode", choices=["print", "txt"], help="Output mode: 'print' or 'txt'")
    parser.add_argument("term", help="Search term (use quotes for phrases)")

    args = parser.parse_args()

    target_directory = args.path
    output_mode = args.mode
    search_term = args.term

    if not os.path.isdir(target_directory):
        print(f"Error: Directory '{target_directory}' not found.")
        sys.exit(1)

    search_results = search_files(target_directory, search_term)

    # form output
    MAX_NAME_LEN = 50
    output_lines = [f"Search term: '{search_term}'", f"Folder: {target_directory}", "-" * (MAX_NAME_LEN + 10)]
    
    for count, file_name in search_results:
        short_name = truncate_filename(file_name, MAX_NAME_LEN)
        output_lines.append(f"{count:4} - {short_name}")
    
    final_output = "\n".join(output_lines)

    if output_mode == "print":
        print(final_output)
    elif output_mode == "txt":
        # get folder name
        folder_name = os.path.basename(os.path.normpath(target_directory))
        # make filename based on folder name and search term
        safe_term = search_term.lower().replace(" ", "-")
        safe_filename = f"{folder_name}_{safe_term}.txt"
        
        try:
            with open(safe_filename, "w", encoding="utf-8") as file:
                file.write(final_output)
            print(f"Results successfully saved to: {safe_filename}")
        except Exception as e:
            print(f"Error saving to file: {e}")