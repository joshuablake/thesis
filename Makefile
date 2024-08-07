LATEX_CMD = ./latexrun --bibtex-cmd=biber $<
SHARED_DEPS = thesis.tex references.bib cam-thesis.cls latex.out/thesis.aux FORCE
INTRODUCTION_DEPS = introduction.tex MCMC-appendix.tex
BIOLOGY_DATA_DEPS = biology-data.tex biology-data/natural-history.png biology-data/ct-calibration.jpg biology-data/CIS-positivity.pdf biology-data/CIS-num-tests.pdf biology-data/CIS-recruitment.pdf biology-data/STATS13734/data_viz.png
INC_PREV_DEPS = incidence-prevalence.tex inc-prev/contact_matrices.png
ATACCC_DEPS = ATACCC.tex ATACCC-appendix-original-analysis.tex ATACCC/typical_trajectory.pdf ATACCC/compare_hakki_modified.pdf ATACCC/mean_trajectories.pdf ATACCC/duration.pdf ATACCC/fits.pdf ATACCC/appendix_fits.pdf ATACCC/fit_individual_55.pdf
IMPERF_DEPS = cis-imperfect-testing.tex cis-imperfect-testing/test-sens-bound.pdf cis-imperfect-testing/sim-single-positive-episodes.pdf cis-imperfect-testing/sim-constant-sensitivity.pdf cis-imperfect-testing/sim-misspecified-sensitivity.pdf cis-imperfect-testing/sim-variable-sensitivity.pdf cis-imperfect-testing/CIS_perfect.pdf cis-imperfect-testing/CIS_final.pdf cis-imperfect-testing/CIS_vary.pdf cis-imperfect-testing/CIS_ntot.pdf
PERF_DEPS = cis-perfect-testing.tex cis-perfect-testing/regions_diag.pdf cis-perfect-testing/double-interval-censor.pdf cis-perfect-testing/truncation.pdf cis-perfect-testing/flat-prior.pdf cis-perfect-testing/kt-prior.pdf cis-perfect-testing/rw2-prior.pdf cis-perfect-testing/vague-prior.pdf cis-perfect-testing/survival-results.pdf cis-perfect-testing/hazard-results.pdf cis-perfect-testing/ataccc-approximation-survival.pdf cis-perfect-testing/ataccc-approximation-hazard.pdf cis-perfect-testing/input-duration-dists.pdf
TRANSMISSION_DEPS = transmission.tex appendix-plots.tex transmission-appendix-INLA.tex transmission-appendix-phase-type.tex SEIR/sim/data.pdf SEIR/sim/predictive_coverage.pdf SEIR/sim/coverage.pdf SEIR/sim/true_vs_posterior.pdf SEIR/CIS/prev_main.pdf SEIR/CIS/prev_appendix.pdf SEIR/CIS/incidence.pdf SEIR/CIS/p_peak.pdf SEIR/CIS/beta_walk.pdf SEIR/CIS/attack_rates.pdf transmission/backcalc-regions.pdf transmission/backcalc-alpha.pdf transmission/backcalc-ages.pdf transmission/backcalc-start-effect.pdf transmission/compare-regions.pdf transmission/compare-NE.pdf
CONCLUSION_DEPS = conclusion.tex
DISTRIBUTIONS_DEPS = distributions.tex

thesis.pdf: $(SHARED_DEPS) $(INTRODUCTION_DEPS) $(BIOLOGY_DATA_DEPS) $(INC_PREV_DEPS) $(ATACCC_DEPS) $(PERF_DEPS) $(IMPERF_DEPS) $(TRANSMISSION_DEPS) $(DISTRIBUTIONS_DEPS) CollegeShields/*.eps
	$(LATEX_CMD)

appendix-plots.pdf: appendix-plots.tex SEIR/CIS/prev_appendix.pdf ATACCC/appendix_fits.pdf $(SHARED_DEPS)
	$(LATEX_CMD)

latex.out/thesis.aux:
	$(LATEX_CMD) thesis.tex

clean:
	./latexrun --clean-all

.PHONY: FORCE

all: thesis.pdf diff appendix-plots.pdf ATACCC-appendix-original-analysis.pdf ATACCC.pdf MCMC-appendix.pdf biology-data.pdf cis-imperfect-testing.pdf cis-perfect-testing.pdf conclusion.pdf distributions.pdf incidence-prevalence.pdf introduction.pdf transmission-appendix-INLA.pdf transmission-appendix-phase-type.pdf transmission.pdf 

#####################################################
## INTRODUCTION CHAPTER

introduction.pdf: $(INTRODUCTION_DEPS) $(SHARED_DEPS)
	$(LATEX_CMD)

MCMC-appendix.pdf: MCMC-appendix.tex $(SHARED_DEPS)
	$(LATEX_CMD)

#####################################################
## BIOLOGY DATA CHAPTER

biology-data/CIS-technical-data.xlsx:
	wget -qO$@ https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/healthandsocialcare/conditionsanddiseases/datasets/covid19infectionsurveytechnicaldata/2022/previous/v6/20220211covid19infectionsurveydatasetstechnical.xlsx

biology-data/CIS-recruitment.pdf: biology-data/CIS-recruitment.R utils.R biology-data/CIS-technical-data.xlsx
	Rscript $<

biology-data/CIS-positivity.pdf biology-data/CIS-num-tests.pdf: biology-data/CIS-positivity.R utils.R transmission/outputs/region.rds SEIR/CIS/data.csv
	Rscript $<

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

ATACCC/fits.pdf ATACCC/appendix_fits.pdf ATACCC/fit_individual_55.pdf: ATACCC/goodness_fit.R utils.R ATACCC/fit.rds ATACCC/data.rds
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

cis-perfect-testing/regions_diag.pdf: cis-perfect-testing/regions_diag.R utils.R
	Rscript $<

cis-perfect-testing/double-interval-censor.pdf cis-perfect-testing/truncation.pdf: cis-perfect-testing/dgp-challenges.R utils.R
	Rscript $<

cis-perfect-testing/ataccc-approximation-%.pdf: cis-perfect-testing/ataccc-approximation.R ATACCC-distributions/posterior_samples.rds ATACCC-distributions/logit_hazard_mean.rds ATACCC-distributions/logit_hazard_cov.rds utils.R
	Rscript $<

cis-perfect-testing/input-duration-dists.pdf: cis-perfect-testing/input-duration-dists.R utils.R cisRuns-output/input_curves.rds
	Rscript $<

cis-perfect-testing/%-prior.pdf: cis-perfect-testing/priors.R utils.R cisRuns-output/input_curves.rds
	Rscript $<

cis-perfect-testing/%-results.pdf: cis-perfect-testing/results.R utils.R cisRuns-output/input_curves.rds cisRuns-output/perfect_posteriors.rds
	Rscript $<

cisRuns-output/%:
	rsync -aq hpc:~/rds/hpc-work/PhD_survival_analysis/output/ cisRuns-output/


#####################################################
## TRANSMISSION CHAPTER

transmission.pdf: $(TRANSMISSION_DEPS) $(SHARED_DEPS)
	$(LATEX_CMD)

transmission-appendix-INLA.pdf: transmission-appendix-INLA.tex $(SHARED_DEPS)
	$(LATEX_CMD)

transmission-appendix-phase-type.pdf: transmission-appendix-phase-type.tex $(SHARED_DEPS)
	$(LATEX_CMD)

#SEIR/CIS/%.pdf: SEIR/CIS.R utils.R SEIR/CIS_results.csv SEIR/CIS_predictive.csv:
#	Rscript $<

SEIR/CIS/attack_rates.pdf: SEIR/CIS/attack_rates.R utils.R transmission/utils.R SEIR/utils.R SEIR/CIS/final_state.csv
	Rscript $<

SEIR/CIS/beta_walk.pdf: SEIR/CIS/random_walk.R utils.R transmission/utils.R SEIR/utils.R SEIR/CIS/params.csv
	Rscript $<

SEIR/CIS/p_peak.pdf SEIR/CIS/incidence.pdf SEIR/CIS/prev_main.pdf SEIR/CIS/prev_appendix.pdf: SEIR/CIS/posterior_predictive.R utils.R transmission/utils.R SEIR/utils.R SEIR/CIS/predictive.csv SEIR/CIS/data.csv SEIR/CIS/params.csv
	Rscript $<

SEIR/CIS/params.csv SEIR/CIS/predictive.csv SEIR/CIS/final_state.csv:
	scp hpc:/rds/user/jbb50/hpc-work/SEIR_model/CIS/*.csv SEIR/CIS/

SEIR/CIS/data.csv:
	scp hpc:/home/jbb50/PhD_work/SEIR_model/SRS_extracts/20230829_STATS18115/modelling_data.csv $@

SEIR/sim/%.csv:
	scp hpc:/rds/user/jbb50/hpc-work/SEIR_model/EoE_fixed/*.csv SEIR/sim/

SEIR/sim/predictive_coverage.pdf: SEIR/sim/predictive_check.R transmission/utils.R utils.R SEIR/sim/sim_output.csv SEIR/sim/posteriors_predictive.csv
	Rscript $<

SEIR/sim/true_vs_posterior.pdf SEIR/sim/coverage.pdf: SEIR/sim/coverage.R utils.R SEIR/sim/posteriors_combined.csv SEIR/sim/true_vals.csv
	Rscript $<

SEIR/sim/data.pdf: SEIR/sim/data.R utils.R transmission/utils.R SEIR/utils.R SEIR/sim/sim_output.csv
	Rscript $<

transmission/backcalc-regions.pdf transmission/backcalc-alpha.pdf: transmission/backcalc-regions.R transmission/outputs/region.rds utils.R
	Rscript $<

transmission/backcalc-ages.pdf: transmission/backcalc-ages.R transmission/outputs/age.rds transmission/utils.R utils.R
	Rscript $<

transmission/backcalc-start-effect.pdf: transmission/backcalc-start-effect.R transmission/outputs/region.rds utils.R
	Rscript $<

transmission/compare-regions.pdf: transmission/compare_regions.R transmission/outputs/region.rds utils.R transmission/utils.R SEIR/CIS/predictive.csv
	Rscript $<

transmission/compare-NE.pdf: transmission/compare_NE.R transmission/outputs/region_age.rds utils.R transmission/utils.R SEIR/CIS/predictive.csv
	Rscript $<

transmission/outputs/%:
	mkdir -p transmission/outputs
	rsync -aq --delete hpc:/home/jbb50/PhD_work/final_backcalc/for_thesis/ transmission/outputs/

#####################################################
## CONCLUSION CHAPTER

conclusion.pdf: $(CONCLUSION_DEPS) $(SHARED_DEPS)
	$(LATEX_CMD)

#####################################################
## DISTRIBUTIONS CHAPTER

distributions.pdf: $(DISTRIBUTIONS_DEPS) $(SHARED_DEPS)
	$(LATEX_CMD)

#####################################################
## FOR APPROVAL - CIS

cis.pdf: cis.tex biology-data/STATS13734/data_viz.pdf $(SHARED_DEPS)
	$(LATEX_CMD)

#####################################################
## SURVIVAL ANALYSIS PAPER

paper-surv-analysis.pdf: paper-surv-analysis.tex $(IMPERF_DEPS) $(PERF_DEPS) $(SHARED_DEPS)
	$(LATEX_CMD)

cis-perf-new-ll.pdf: cis-perf-new-ll.tex $(SHARED_DEPS)
	$(LATEX_CMD)



#####################################################
## DIFFS

diff: thesis-diff.pdf thesis-diff-list.pdf

thesis-diff.pdf: thesis-diff.tex $(SHARED_DEPS)
	$(LATEX_CMD)

thesis-diff.tex: latex.out/thesis-prev.tex latex.out/thesis-cur.tex
	latexdiff --append-mboxsafecmd=autocite,textcite,cref --math-markup=3 latex.out/thesis-prev.tex latex.out/thesis-cur.tex > thesis-diff.tex

latex.out/thesis-prev.tex: ../thesis-repos/orig-submission/thesis.tex
	python3 parse_subfiles.py ../thesis-repos/orig-submission/thesis.tex $@

latex.out/thesis-cur.tex: thesis.pdf
	python3 parse_subfiles.py thesis.tex $@

thesis-diff-list.pdf: generate_changes_report.py thesis-diff.tex
	python3 $< thesis-diff.tex $@