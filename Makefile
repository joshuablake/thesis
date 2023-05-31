LATEX_CMD = ./latexrun --bibtex-cmd=biber $<
main.pdf: main.tex cis-imperfect-testing.pdf cis-perfect-testing.pdf references.bib PhDThesisPSnPDF.cls  CollegeShields/*.eps
	$(LATEX_CMD)

cis-imperfect-testing.pdf: cis-imperfect-testing.tex main.tex references.bib PhDThesisPSnPDF.cls
	$(LATEX_CMD)

cis-perfect-testing.pdf: cis-perfect-testing.tex main.tex references.bib PhDThesisPSnPDF.cls cis-perfect-testing/regions_diag.png cis-perfect-testing/double-interval-censor.png cis-perfect-testing/truncation.png
	$(LATEX_CMD)

cis-perfect-testing/regions_diag.png: cis-perfect-testing/regions_diag.R
	Rscript $<

cis-perfect-testing/double-interval-censor.png cis-perfect-testing/truncation.png: cis-perfect-testing/dgp-challenges.R
	Rscript $<

clean:
	./latexrun --clean

all: main.pdf