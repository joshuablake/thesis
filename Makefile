LATEX_CMD = ./latexrun --bibtex-cmd=biber $<
SHARED_DEPS = thesis.tex references.bib cam-thesis.cls
IMPERF_DEPS = cis-imperfect-testing.tex
PERF_DEPS = cis-perfect-testing.tex cis-perfect-testing/regions_diag.png cis-perfect-testing/double-interval-censor.png cis-perfect-testing/truncation.png

thesis.pdf: $(SHARED_DEPS) $(IMPERF_DEPS) $(PERF_DEPS) CollegeShields/*.eps
	$(LATEX_CMD)

cis-imperfect-testing.pdf: $(IMPERF_DEPS) $(SHARED_DEPS)
	$(LATEX_CMD)

cis-perfect-testing.pdf: $(PERF_DEPS) $(SHARED_DEPS)
	$(LATEX_CMD)

cis-perfect-testing/regions_diag.png: cis-perfect-testing/regions_diag.R
	Rscript $<

cis-perfect-testing/double-interval-censor.png cis-perfect-testing/truncation.png: cis-perfect-testing/dgp-challenges.R
	Rscript $<

clean:
	./latexrun --clean

all: thesis.pdf cis-imperfect-testing.pdf cis-perfect-testing.pdf