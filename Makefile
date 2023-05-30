LATEX_CMD = ./latexrun --bibtex-cmd=biber $<

main.pdf: main.tex cis-imperfect-testing.pdf cis-perfect-testing.pdf references.bib
	$(LATEX_CMD)

cis-imperfect-testing.pdf: cis-imperfect-testing.tex references.bib
	$(LATEX_CMD)

cis-perfect-testing.pdf: cis-perfect-testing.tex references.bib cis-perfect-testing/regions_diag.png
	$(LATEX_CMD)

cis-perfect-testing/regions_diag.png: cis-perfect-testing/regions_diag.R
	Rscript $<

clean:
	./latexrun --clean

all: main.pdf