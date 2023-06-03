LATEX_CMD = ./latexrun --bibtex-cmd=biber $<
SHARED_DEPS = thesis.tex references.bib cam-thesis.cls
IMPERF_DEPS = cis-imperfect-testing.tex
PERF_DEPS = cis-perfect-testing.tex cis-perfect-testing/regions_diag.png cis-perfect-testing/double-interval-censor.png cis-perfect-testing/truncation.png cis-perfect-testing/flat-prior.png cis-perfect-testing/vague-prior.png cis-perfect-testing/survival-results.png cis-perfect-testing/hazard-results.png cis-perfect-testing/hazard-pairs-results.png

thesis.pdf: $(SHARED_DEPS) $(IMPERF_DEPS) $(PERF_DEPS) CollegeShields/*.eps
	$(LATEX_CMD)

clean:
	./latexrun --clean

all: thesis.pdf cis-imperfect-testing.pdf cis-perfect-testing.pdf

#####################################################
## IMPERFECT TESTING CHAPTER

cis-imperfect-testing.pdf: $(IMPERF_DEPS) $(SHARED_DEPS)
	$(LATEX_CMD)

#####################################################
## PERFECT TESTING CHAPTER

cis-perfect-testing.pdf: $(PERF_DEPS) $(SHARED_DEPS)
	$(LATEX_CMD)

cis-perfect-testing/regions_diag.png: cis-perfect-testing/regions_diag.R
	Rscript $<

cis-perfect-testing/double-interval-censor.png cis-perfect-testing/truncation.png: cis-perfect-testing/dgp-challenges.R
	Rscript $<

cis-perfect-testing/%-prior.png: cis-perfect-testing/priors.R utils.R cisRuns-output/input_curves.rds
	Rscript $<

cis-perfect-testing/%-results.png: cis-perfect-testing/results.R utils.R cisRuns-output/input_curves.rds cisRuns-output/perfect_posteriors.rds cisRuns-output/vague_perfect_hazard_posterior_samples.rds
	Rscript $<

cisRuns-output/%:
	rsync -aq hpc:~/modular-cis-sims/cisRuns/outputs/thesis/ cisRuns-output/