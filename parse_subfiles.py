import re
import os
import sys

def replace_subfiles(main_file, output_file):
    with open(main_file, 'r') as file:
        main_content = file.read()

    # Regex to find \subfile{filename} commands
    subfile_pattern = re.compile(r'\\subfile\{([^\}]+)\}')

    def get_subfile_content(match):
        subfile_path = match.group(1)
        if not subfile_path.endswith('.tex'):
            subfile_path += '.tex'
        if not os.path.isabs(subfile_path):
            subfile_path = os.path.join(os.path.dirname(main_file), subfile_path)

        try:
            with open(subfile_path, 'r') as subfile:
                content = subfile.read()
                # Strip preamble and \begin{document}, \end{document}
                content = re.sub(r'(?s)^.*?\\begin\{document\}', '', content)
                content = re.sub(r'\\end\{document\}.*$', '', content)
                return content.strip()
        except FileNotFoundError:
            print(f"Subfile not found: {subfile_path}")
            return match.group(0)  # Keep the original \subfile command if file not found

    # Replace all \subfile commands with the content of the respective subfiles
    new_content = re.sub(subfile_pattern, get_subfile_content, main_content)

    # Output the result to a new file
    with open(output_file, 'w') as file:
        file.write(new_content)

    print(f"Processed file saved as {output_file}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python replace_subfiles.py <input_file> <output_file>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    replace_subfiles(input_file, output_file)