import re
import sys
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas

# Extract changes function
def extract_changes(diff_tex_path):
    with open(diff_tex_path, 'r') as file:
        content = file.read()

    additions = re.findall(r'\\DIFadd{(.*?)}', content, re.DOTALL)
    deletions = re.findall(r'\\DIFdel{(.*?)}', content, re.DOTALL)

    additions = [add.strip() for add in additions]
    deletions = [del_.strip() for del_ in deletions]

    # Filter out identical additions and deletions
    changes = {
        "additions": additions,
        "deletions": deletions,
    }

    return changes

# Generate PDF report function
def generate_report(changes, output_pdf_path):
    c = canvas.Canvas(output_pdf_path, pagesize=letter)
    width, height = letter

    c.setFont("Helvetica", 12)
    text_object = c.beginText(40, height - 40)
    text_object.setTextOrigin(40, height - 40)

    text_object.textLine("List of Changes")
    text_object.moveCursor(0, 20)

    for change_type, changes_list in changes.items():
        text_object.textLine(f"\n{change_type.capitalize()}:")
        for change in changes_list:
            text_object.textLine(f"- {change.strip()}")

    c.drawText(text_object)
    c.save()

def main():
    if len(sys.argv) != 3:
        print("Usage: python generate_changes_report.py <diff.tex> <output.pdf>")
        sys.exit(1)

    diff_tex_path = sys.argv[1]
    output_pdf_path = sys.argv[2]

    changes = extract_changes(diff_tex_path)
    generate_report(changes, output_pdf_path)

if __name__ == "__main__":
    main()
