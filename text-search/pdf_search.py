import os
import sys
import fitz  # PyMuPDF
import argparse

def search_pdfs(directory_path, search_term):
    results = []
    search_term_lower = search_term.lower()

    for filename in os.listdir(directory_path):
        if filename.lower().endswith(".pdf"):
            file_path = os.path.join(directory_path, filename)
            match_count = 0
            
            try:
                pdf_document = fitz.open(file_path)
                for page_num in range(pdf_document.page_count):
                    page = pdf_document.load_page(page_num)
                    text = page.get_text("text").lower()
                    match_count += text.count(search_term_lower)
                
                pdf_document.close()
                results.append((match_count, filename))
                
            except Exception as e:
                print(f"Error reading {filename}: {e}")

    # Sort results by match_count descending (highest first)
    results.sort(key=lambda x: x[0], reverse=True)
    return results

def truncate_filename(filename, max_length):
    if len(filename) > max_length:
        return filename[:max_length - 3] + "..."
    return filename

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Search PDFs for a specific phrase.")
    parser.add_argument("path", help="Path to the folder containing PDFs")
    parser.add_argument("mode", choices=["print", "txt"], help="Output mode: 'print' or 'txt'")
    parser.add_argument("term", help="Search term (use quotes for phrases)")

    args = parser.parse_args()

    target_directory = args.path
    output_mode = args.mode
    search_term = args.term

    if not os.path.isdir(target_directory):
        print(f"Error: Directory '{target_directory}' not found.")
        sys.exit(1)

    search_results = search_pdfs(target_directory, search_term)

    # Output formatting settings
    MAX_NAME_LEN = 50
    output_lines = [f"Search term: '{search_term}'", "-" * (MAX_NAME_LEN + 10)]
    
    for count, pdf_name in search_results:
        short_name = truncate_filename(pdf_name, MAX_NAME_LEN)
        output_lines.append(f"{count:4} - {short_name}")
    
    final_output = "\n".join(output_lines)

    if output_mode == "print":
        print(final_output)
    elif output_mode == "txt":
        safe_filename = search_term.lower().replace(" ", "-") + ".txt"
        try:
            with open(safe_filename, "w", encoding="utf-8") as file:
                file.write(final_output)
            print(f"Results successfully saved to: {safe_filename}")
        except Exception as e:
            print(f"Error saving to file: {e}")