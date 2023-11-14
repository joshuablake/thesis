LATEX_CMD = ./latexrun --bibtex-cmd=biber $<
SHARED_DEPS = thesis.tex references.bib cam-thesis.cls latex.out/thesis.aux FORCE
ATACCC_DEPS = ATACCC.tex ATACCC-appendix-original-analysis.tex ATACCC/typical_trajectory.png ATACCC/compare_hakki_modified.png ATACCC/mean_trajectories.png ATACCC/duration.png ATACCC/fits.png ATACCC/fit_individual_55.png
IMPERF_DEPS = cis-imperfect-testing.tex
PERF_DEPS = cis-perfect-testing.tex cis-perfect-testing/regions_diag.png cis-perfect-testing/double-interval-censor.png cis-perfect-testing/truncation.png cis-perfect-testing/flat-prior.png cis-perfect-testing/kt-prior.png cis-perfect-testing/rw2-prior.png cis-perfect-testing/vague-prior.png cis-perfect-testing/survival-results.png cis-perfect-testing/hazard-results.png cis-perfect-testing/ataccc-approximation-survival.png cis-perfect-testing/ataccc-approximation-hazard.png cis-perfect-testing/input-duration-dists.png
INC_PREV_DEPS = incidence-prevalence.tex
SEIR_DEPS = SEIR.tex
DISTRIBUTIONS_DEPS = distributions.tex

thesis.pdf: $(SHARED_DEPS) $(ATACCC_DEPS) $(IMPERF_DEPS) $(PERF_DEPS) $(INC_PREV_DEPS) $(SEIR_DEPS) $(DISTRIBUTIONS_DEPS) CollegeShields/*.eps
	$(LATEX_CMD)

latex.out/thesis.aux:
	$(LATEX_CMD) thesis.tex

clean:
	./latexrun --clean-all

.PHONY: FORCE

all: thesis.pdf cis-imperfect-testing.pdf cis-perfect-testing.pdf incidence-prevalence.pdf SEIR.pdf

#####################################################
## INCIDENCE PREVALENCE CHAPTER

incidence-prevalence.pdf: $(INC_PREV_DEPS) $(SHARED_DEPS)
	$(LATEX_CMD)

#####################################################
## ATACCC CHAPTER
ATACCC/typical_trajectory.png: ATACCC/trajectories.R utils.R
	Rscript $<

ATACCC.pdf: $(ATACCC_DEPS) $(SHARED_DEPS)
	$(LATEX_CMD)

ATACCC-distributions/%:
	rsync -aq bsu:~/COVID/ons-incidence/duration_estimation/SARS-CoV-2-viral-shedding-dynamics/for_thesis/ ATACCC-distributions/

ATACCC-appendix-original-analysis.pdf: ATACCC-appendix-original-analysis.tex $(SHARED_DEPS)
	$(LATEX_CMD)

ATACCC/compare_hakki_modified.png ATACCC/mean_trajectories.png: ATACCC/posteriors.R utils.R ATACCC/fit.rds ATACCC/fit2.rds
	Rscript $<

ATACCC/fits.png ATACCC/fit_individual_55.png: ATACCC/goodness_fit.R utils.R ATACCC/fit.rds ATACCC/data.rds
	Rscript $<

ATACCC/duration.png: ATACCC/duration.R utils.R ATACCC-distributions/posterior_samples2.rds
	Rscript $<


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


#####################################################
## SEIR CHAPTER

SEIR.pdf: $(SEIR_DEPS) $(SHARED_DEPS)
	$(LATEX_CMD)

#SEIR/CIS-.png: SEIR/CIS.R utils.R SEIR/CIS_results.csv SEIR/CIS_predictive.csv:
	#Rscript $<

SEIR/CIS_params.csv:
	scp hpc:/rds/user/jbb50/hpc-work/SEIR_model/CIS/posteriors_combined.csv $@

SEIR/CIS_predictive.csv:
	scp hpc:/rds/user/jbb50/hpc-work/SEIR_model/CIS/posteriors_predictive.csv $@

#####################################################
## DISTRIBUTIONS CHAPTER

distributions.pdf: $(DISTRIBUTIONS_DEPS) $(SHARED_DEPS)
	$(LATEX_CMD)