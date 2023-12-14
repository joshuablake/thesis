LATEX_CMD = ./latexrun --bibtex-cmd=biber $<
SHARED_DEPS = thesis.tex references.bib refs-custom.bib cam-thesis.cls latex.out/thesis.aux FORCE
BIOLOGY_DATA_DEPS = biology-data.tex
INC_PREV_DEPS = incidence-prevalence.tex
ATACCC_DEPS = ATACCC.tex ATACCC-appendix-original-analysis.tex ATACCC/typical_trajectory.png ATACCC/compare_hakki_modified.png ATACCC/mean_trajectories.png ATACCC/duration.png ATACCC/fits.png ATACCC/fit_individual_55.png
IMPERF_DEPS = cis-imperfect-testing.tex cis-imperfect-testing/test-sens-bound.png cis-imperfect-testing/sim-single-positive-episodes.png cis-imperfect-testing/sim-constant-sensitivity.png cis-imperfect-testing/sim-misspecified-sensitivity.png cis-imperfect-testing/sim-variable-sensitivity.png
PERF_DEPS = cis-perfect-testing.tex cis-perfect-testing/regions_diag.png cis-perfect-testing/double-interval-censor.png cis-perfect-testing/truncation.png cis-perfect-testing/flat-prior.png cis-perfect-testing/kt-prior.png cis-perfect-testing/rw2-prior.png cis-perfect-testing/vague-prior.png cis-perfect-testing/survival-results.png cis-perfect-testing/hazard-results.png cis-perfect-testing/ataccc-approximation-survival.png cis-perfect-testing/ataccc-approximation-hazard.png cis-perfect-testing/input-duration-dists.png
BACKCALC_DEPS = backcalc.tex
SEIR_DEPS = SEIR.tex SEIR/contact_matrices.png SEIR/sim/data.png SEIR/sim/predictive_coverage.png SEIR/sim/coverage.pdf SEIR/sim/true_vs_posterior.png SEIR/CIS/prev_young.png SEIR/CIS/prev_old.png SEIR/CIS/incidence.png SEIR/CIS/p_peak.png SEIR/CIS/beta_walk.pdf SEIR/CIS/attack_rates.png
DISTRIBUTIONS_DEPS = distributions.tex

thesis.pdf: $(SHARED_DEPS) $(BIOLOGY_DATA_DEPS) $(INC_PREV_DEPS) $(ATACCC_DEPS) $(PERF_DEPS) $(IMPERF_DEPS) $(SEIR_DEPS) $(DISTRIBUTIONS_DEPS) CollegeShields/*.eps
	$(LATEX_CMD)

latex.out/thesis.aux:
	$(LATEX_CMD) thesis.tex

clean:
	./latexrun --clean-all

.PHONY: FORCE

all: thesis.pdf biology-data.pdf incidence-prevalence.pdf ATACCC.pdf ATACCC-appendix-original-analysis.pdf cis-imperfect-testing.pdf cis-perfect-testing.pdf incidence-prevalence.pdf SEIR.pdf distributions.pdf

#####################################################
## BIOLOGY DATA CHAPTER

biology-data.pdf: $(BIOLOGY_DATA_DEPS) $(SHARED_DEPS)
	$(LATEX_CMD)

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

cis-imperfect-testing/test-sens-bound.png: cis-imperfect-testing/test_sens_bound.R utils.R cis-imperfect-testing/STATS18596/changing-sensitivity/results_by_day_of_episode.csv
	Rscript $<

cis-imperfect-testing/sim-single-positive-episodes.png: cis-imperfect-testing/sim_single_positive_episodes.R utils.R cisRuns-output/sim_reps.rds
	Rscript $<

cis-imperfect-testing/sim-constant-sensitivity.png cis-imperfect-testing/sim-misspecified-sensitivity.png cis-imperfect-testing/sim-variable-sensitivity.png: cis-imperfect-testing/sim_survival.R utils.R cisRuns-output/all_posteriors.rds cisRuns-output/input_curves.rds
	Rscript $<

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
## BACKCALC CHAPTER

backcalc.pdf: $(BACKCALC_DEPS) $(SHARED_DEPS)
	$(LATEX_CMD)

#####################################################
## SEIR CHAPTER

SEIR.pdf: $(SEIR_DEPS) $(SHARED_DEPS)
	$(LATEX_CMD)

#SEIR/CIS/%.png: SEIR/CIS.R utils.R SEIR/CIS_results.csv SEIR/CIS_predictive.csv:
#	Rscript $<

SEIR/CIS/attack_rates.png: SEIR/CIS/attack_rates.R utils.R SEIR/utils.R SEIR/CIS/final_state.csv
	Rscript $<

SEIR/CIS/beta_walk.pdf: SEIR/CIS/random_walk.R utils.R SEIR/utils.R SEIR/CIS/params.csv
	Rscript $<

SEIR/CIS/p_peak.png SEIR/CIS/incidence.png SEIR/CIS/prev_young.png SEIR/CIS/prev_old.png: SEIR/CIS/posterior_predictive.R utils.R SEIR/utils.R SEIR/CIS/predictive.csv SEIR/CIS/data.csv SEIR/CIS/params.csv
	Rscript $<

SEIR/CIS/params.csv SEIR/CIS/predictive.csv SEIR/CIS/final_state.csv:
	scp hpc:/rds/user/jbb50/hpc-work/SEIR_model/CIS/*.csv SEIR/CIS/

SEIR/CIS/data.csv:
	scp hpc:/home/jbb50/PhD_work/SEIR_model/SRS_extracts/20230829_STATS18115/modelling_data.csv $@

SEIR/sim/%.csv:
	scp hpc:/rds/user/jbb50/hpc-work/SEIR_model/EoE_fixed/*.csv SEIR/sim/

SEIR/sim/predictive_coverage.png: SEIR/sim/predictive_check.R utils.R SEIR/sim/sim_output.csv SEIR/sim/posteriors_predictive.csv
	Rscript $<

SEIR/sim/true_vs_posterior.png SEIR/sim/coverage.pdf: SEIR/sim/coverage.R utils.R SEIR/sim/posteriors_combined.csv SEIR/sim/true_vals.csv
	Rscript $<

SEIR/sim/data.png: SEIR/sim/data.R utils.R SEIR/utils.R SEIR/sim/sim_output.csv
	Rscript $<

#####################################################
## DISTRIBUTIONS CHAPTER

distributions.pdf: $(DISTRIBUTIONS_DEPS) $(SHARED_DEPS)
	$(LATEX_CMD)