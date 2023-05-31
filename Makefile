LATEX_CMD = ./latexrun --bibtex-cmd=biber $<
SHARED_DEPS = main.tex references.bib cam-thesis.cls
IMPERF_DEPS = cis-imperfect-testing.tex
PERF_DEPS = cis-perfect-testing.tex cis-perfect-testing/regions_diag.png cis-perfect-testing/double-interval-censor.png cis-perfect-testing/truncation.png

main.pdf: $(SHARED_DEPS) $(IMPERF_DEPS) $(PERF_DEPS) CollegeShields/*.eps
	$(LATEX_CMD)

cis-imperfect-testing.pdf: $(SHARED_DEPS) $(IMPERF_DEPS)
	$(LATEX_CMD)

cis-perfect-testing.pdf: $(SHARED_DEPS) $(PERF_DEPS)
	$(LATEX_CMD)

cis-perfect-testing/regions_diag.png: cis-perfect-testing/regions_diag.R
	Rscript $<

cis-perfect-testing/double-interval-censor.png cis-perfect-testing/truncation.png: cis-perfect-testing/dgp-challenges.R
	Rscript $<

clean:
	./latexrun --clean

all: main.pdf