LATEX_CMD = ./latexrun --bibtex-cmd=biber $<
SHARED_DEPS = thesis.tex references.bib cam-thesis.cls latex.out/thesis.aux FORCE
IMPERF_DEPS = cis-imperfect-testing.tex
PERF_DEPS = cis-perfect-testing.tex cis-perfect-testing/regions_diag.png cis-perfect-testing/double-interval-censor.png cis-perfect-testing/truncation.png cis-perfect-testing/flat-prior.png cis-perfect-testing/vague-prior.png cis-perfect-testing/survival-results.png cis-perfect-testing/hazard-results.png cis-perfect-testing/ataccc-approximation-survival.png cis-perfect-testing/ataccc-approximation-hazard.png cis-perfect-testing/input-duration-dists.png
INC_PREV_DEPS = incidence-prevalence.tex

thesis.pdf: $(SHARED_DEPS) $(IMPERF_DEPS) $(PERF_DEPS) $(INC_PREV_DEPS) CollegeShields/*.eps
	$(LATEX_CMD)

latex.out/thesis.aux:
	$(LATEX_CMD) thesis.tex

clean:
	./latexrun --clean-all

.PHONY: FORCE

all: thesis.pdf cis-imperfect-testing.pdf cis-perfect-testing.pdf incidence-prevalence.pdf

#####################################################
## INCIDENCE PREVALENCE CHAPTER

incidence-prevalence.pdf: $(INC_PREV_DEPS) $(SHARED_DEPS)
	$(LATEX_CMD)

#####################################################
## ATACCC CHAPTER

ATACCC-distributions/%:
	rsync -aq bsu:~/COVID/ons-incidence/duration_estimation/SARS-CoV-2-viral-shedding-dynamics/for_thesis/ ATACCC-distributions/

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

cis-perfect-testing/ataccc-approximation-%.png: cis-perfect-testing/ataccc-approximation.R ATACCC-distributions/posterior_samples.rds ATACCC-distributions/logit_hazard_mean.rds ATACCC-distributions/logit_hazard_cov.rds utils.R
	Rscript $<

cis-perfect-testing/input-duration-dists.png: cis-perfect-testing/input-duration-dists.R utils.R cisRuns-output/input_curves.rds
	Rscript $<

cis-perfect-testing/%-prior.png: cis-perfect-testing/priors.R utils.R cisRuns-output/input_curves.rds
	Rscript $<

cis-perfect-testing/%-results.png: cis-perfect-testing/results.R utils.R cisRuns-output/input_curves.rds cisRuns-output/perfect_posteriors.rds cisRuns-output/vague_perfect_hazard_posterior_samples.rds
	Rscript $<

cisRuns-output/%:
	rsync -aq hpc:~/modular-cis-sims/cisRuns/outputs/thesis/ cisRuns-output/