LATEX_CMD = ./latexrun --bibtex-cmd=biber $<
SHARED_DEPS = thesis.tex references.bib refs-custom.bib cam-thesis.cls latex.out/thesis.aux FORCE
INTRODUCTION_DEPS = introduction.tex
BIOLOGY_DATA_DEPS = biology-data.tex biology-data/natural-history.png
INC_PREV_DEPS = incidence-prevalence.tex inc-prev/contact_matrices.png
ATACCC_DEPS = ATACCC.tex ATACCC-appendix-original-analysis.tex ATACCC/typical_trajectory.pdf ATACCC/compare_hakki_modified.pdf ATACCC/mean_trajectories.pdf ATACCC/duration.pdf ATACCC/fits.pdf ATACCC/fit_individual_55.pdf
IMPERF_DEPS = cis-imperfect-testing.tex cis-imperfect-testing/test-sens-bound.pdf cis-imperfect-testing/sim-single-positive-episodes.pdf cis-imperfect-testing/sim-constant-sensitivity.pdf cis-imperfect-testing/sim-misspecified-sensitivity.pdf cis-imperfect-testing/sim-variable-sensitivity.pdf cis-imperfect-testing/CIS_perfect.pdf cis-imperfect-testing/CIS_final.pdf cis-imperfect-testing/CIS_vary.pdf cis-imperfect-testing/CIS_ntot.pdf
PERF_DEPS = cis-perfect-testing.tex cis-perfect-testing/regions_diag.pdf cis-perfect-testing/double-interval-censor.pdf cis-perfect-testing/truncation.pdf cis-perfect-testing/flat-prior.pdf cis-perfect-testing/kt-prior.pdf cis-perfect-testing/rw2-prior.pdf cis-perfect-testing/vague-prior.pdf cis-perfect-testing/survival-results.pdf cis-perfect-testing/hazard-results.pdf cis-perfect-testing/ataccc-approximation-survival.pdf cis-perfect-testing/ataccc-approximation-hazard.pdf cis-perfect-testing/input-duration-dists.pdf
TRANSMISSION_DEPS = transmission.tex SEIR/sim/data.pdf SEIR/sim/predictive_coverage.pdf SEIR/sim/coverage.pdf SEIR/sim/true_vs_posterior.pdf SEIR/CIS/prev_young.pdf SEIR/CIS/prev_old.pdf SEIR/CIS/incidence.pdf SEIR/CIS/p_peak.pdf SEIR/CIS/beta_walk.pdf SEIR/CIS/attack_rates.pdf transmission/backcalc-regions.pdf transmission/backcalc-ages.pdf transmission/backcalc-start-effect.pdf
DISTRIBUTIONS_DEPS = distributions.tex

thesis.pdf: $(SHARED_DEPS) $(INTRODUCTION_DEPS) $(BIOLOGY_DATA_DEPS) $(INC_PREV_DEPS) $(ATACCC_DEPS) $(PERF_DEPS) $(IMPERF_DEPS) $(TRANSMISSION_DEPS) $(DISTRIBUTIONS_DEPS) CollegeShields/*.eps
	$(LATEX_CMD)

latex.out/thesis.aux:
	$(LATEX_CMD) thesis.tex

clean:
	./latexrun --clean-all

.PHONY: FORCE

all: thesis.pdf introduction.pdf biology-data.pdf incidence-prevalence.pdf ATACCC.pdf cis-imperfect-testing.pdf cis-perfect-testing.pdf transmission.pdf distributions.pdf

#####################################################
## INTRODUCTION CHAPTER

introduction.pdf: $(INTRODUCTION_DEPS) $(SHARED_DEPS)
	$(LATEX_CMD)

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
ATACCC/typical_trajectory.pdf: ATACCC/trajectories.R utils.R
	Rscript $<

ATACCC.pdf: $(ATACCC_DEPS) $(SHARED_DEPS)
	$(LATEX_CMD)

ATACCC-distributions/%:
	rsync -aq bsu:~/COVID/ons-incidence/duration_estimation/SARS-CoV-2-viral-shedding-dynamics/for_thesis/ ATACCC-distributions/

ATACCC-appendix-original-analysis.pdf: ATACCC-appendix-original-analysis.tex $(SHARED_DEPS)
	$(LATEX_CMD)

ATACCC/compare_hakki_modified.pdf ATACCC/mean_trajectories.pdf: ATACCC/posteriors.R utils.R ATACCC/fit.rds ATACCC/fit2.rds
	Rscript $<

ATACCC/fits.pdf ATACCC/fit_individual_55.pdf: ATACCC/goodness_fit.R utils.R ATACCC/fit.rds ATACCC/data.rds
	Rscript $<

ATACCC/duration.pdf: ATACCC/duration.R utils.R ATACCC-distributions/posterior_samples2.rds
	Rscript $<


#####################################################
## IMPERFECT TESTING CHAPTER

cis-imperfect-testing.pdf: $(IMPERF_DEPS) $(SHARED_DEPS)
	$(LATEX_CMD)

cis-imperfect-testing/test-sens-bound.pdf: cis-imperfect-testing/test_sens_bound.R utils.R cis-imperfect-testing/STATS18596/changing-sensitivity/results_by_day_of_episode.csv
	Rscript $<

cis-imperfect-testing/sim-single-positive-episodes.pdf: cis-imperfect-testing/sim_single_positive_episodes.R utils.R cisRuns-output/sim_reps.rds
	Rscript $<

cis-imperfect-testing/sim-constant-sensitivity.pdf cis-imperfect-testing/sim-misspecified-sensitivity.pdf cis-imperfect-testing/sim-variable-sensitivity.pdf: cis-imperfect-testing/sim_survival.R utils.R cisRuns-output/all_posteriors.rds cisRuns-output/input_curves.rds
	Rscript $<

cis-imperfect-testing/CIS_perfect.pdf cis-imperfect-testing/CIS_final.pdf cis-imperfect-testing/CIS_vary.pdf: cis-imperfect-testing/CIS_survival.R utils.R cis-imperfect-testing/STATS17701/draws.rds ATACCC-distributions/posterior_samples.rds
	Rscript $<

cis-imperfect-testing/CIS_ntot.pdf: cis-imperfect-testing/CIS_ntot.R utils.R cis-imperfect-testing/STATS18744/means.rds
	Rscript $<

#####################################################
## PERFECT TESTING CHAPTER

cis-perfect-testing.pdf: $(PERF_DEPS) $(SHARED_DEPS)
	$(LATEX_CMD)

cis-perfect-testing/regions_diag.pdf: cis-perfect-testing/regions_diag.R
	Rscript $<

cis-perfect-testing/double-interval-censor.pdf cis-perfect-testing/truncation.pdf: cis-perfect-testing/dgp-challenges.R
	Rscript $<

cis-perfect-testing/ataccc-approximation-%.pdf: cis-perfect-testing/ataccc-approximation.R ATACCC-distributions/posterior_samples.rds ATACCC-distributions/logit_hazard_mean.rds ATACCC-distributions/logit_hazard_cov.rds utils.R
	Rscript $<

cis-perfect-testing/input-duration-dists.pdf: cis-perfect-testing/input-duration-dists.R utils.R cisRuns-output/input_curves.rds
	Rscript $<

cis-perfect-testing/%-prior.pdf: cis-perfect-testing/priors.R utils.R cisRuns-output/input_curves.rds
	Rscript $<

cis-perfect-testing/%-results.pdf: cis-perfect-testing/results.R utils.R cisRuns-output/input_curves.rds cisRuns-output/perfect_posteriors.rds cisRuns-output/vague_perfect_hazard_posterior_samples.rds
	Rscript $<

cisRuns-output/%:
	rsync -aq hpc:~/modular-cis-sims/cisRuns/outputs/thesis/ cisRuns-output/


#####################################################
## TRANSMISSION CHAPTER

transmission.pdf: $(TRANSMISSION_DEPS) $(SHARED_DEPS)
	$(LATEX_CMD)

#SEIR/CIS/%.pdf: SEIR/CIS.R utils.R SEIR/CIS_results.csv SEIR/CIS_predictive.csv:
#	Rscript $<

SEIR/CIS/attack_rates.pdf: SEIR/CIS/attack_rates.R utils.R SEIR/utils.R SEIR/CIS/final_state.csv
	Rscript $<

SEIR/CIS/beta_walk.pdf: SEIR/CIS/random_walk.R utils.R SEIR/utils.R SEIR/CIS/params.csv
	Rscript $<

SEIR/CIS/p_peak.pdf SEIR/CIS/incidence.pdf SEIR/CIS/prev_young.pdf SEIR/CIS/prev_old.pdf: SEIR/CIS/posterior_predictive.R utils.R SEIR/utils.R SEIR/CIS/predictive.csv SEIR/CIS/data.csv SEIR/CIS/params.csv
	Rscript $<

SEIR/CIS/params.csv SEIR/CIS/predictive.csv SEIR/CIS/final_state.csv:
	scp hpc:/rds/user/jbb50/hpc-work/SEIR_model/CIS/*.csv SEIR/CIS/

SEIR/CIS/data.csv:
	scp hpc:/home/jbb50/PhD_work/SEIR_model/SRS_extracts/20230829_STATS18115/modelling_data.csv $@

SEIR/sim/%.csv:
	scp hpc:/rds/user/jbb50/hpc-work/SEIR_model/EoE_fixed/*.csv SEIR/sim/

SEIR/sim/predictive_coverage.pdf: SEIR/sim/predictive_check.R utils.R SEIR/sim/sim_output.csv SEIR/sim/posteriors_predictive.csv
	Rscript $<

SEIR/sim/true_vs_posterior.pdf SEIR/sim/coverage.pdf: SEIR/sim/coverage.R utils.R SEIR/sim/posteriors_combined.csv SEIR/sim/true_vals.csv
	Rscript $<

SEIR/sim/data.pdf: SEIR/sim/data.R utils.R SEIR/utils.R SEIR/sim/sim_output.csv
	Rscript $<

transmission/backcalc-regions.pdf: transmission/backcalc-regions.R transmission/outputs/region_incidence.rds utils.R
	Rscript $<

transmission/backcalc-ages.pdf: transmission/backcalc-ages.R transmission/outputs/age_incidence.rds utils.R
	Rscript $<

transmission/backcalc-start-effect.pdf: transmission/backcalc-start-effect.R transmission/outputs/region_incidence.rds utils.R
	Rscript $<

transmission/outputs/%:
	mkdir -p transmission/outputs
	rsync -aq hpc:/home/jbb50/PhD_work/final_backcalc/for_thesis/ transmission/outputs/

#####################################################
## DISTRIBUTIONS CHAPTER

distributions.pdf: $(DISTRIBUTIONS_DEPS) $(SHARED_DEPS)
	$(LATEX_CMD)