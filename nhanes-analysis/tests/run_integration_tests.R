# Artificial survey data: no records are sampled from NHANES.
source('R/00_utils.R')
source('R/01_outcome_specifications.R')
source('R/02_prepare_analysis_data.R')
source('R/03_multiple_imputation.R')
source('R/04_survey_model.R')
set.seed(631)
n <- 800L
d <- data.frame(SEQN=seq_len(n),cycle=rep(c('2011-2012','2013-2014'),each=n/2),
 sleep_anchored_mvpa_phase_h=runif(n,8,15),RIDAGEYR=runif(n,20,80),
 sex_model=sample(c('Male','Female'),n,TRUE),
 race4=sample(c('Non-Hispanic White','Non-Hispanic Black','Hispanic','Other'),n,TRUE),
 education_binary=sample(c('Others','Less than high school'),n,TRUE),
 household_income_binary=sample(c('>= $20k','<$20k'),n,TRUE),
 smoking_binary=sample(c('No','Yes'),n,TRUE),alcohol_binary=sample(c('No','Yes'),n,TRUE),
 total_energy_intake_kcal=runif(n,1000,3000),HEI_score=runif(n,20,90),
 mean_mvpa_minutes_per_valid_day=runif(n,10,120),mean_sleep_duration_h=runif(n,5,9),
 SDMVSTRA=rep(1:40,each=20),SDMVPSU=rep(rep(1:2,each=10),40),
 WTMEC4YR=runif(n,100,2000),WTSAF4YR=runif(n,100,3000),WTSOG4YR=runif(n,100,4000))
for(v in imputed_covariates) d[sample(n,40),v] <- NA
all_results <- list()
for(key in names(outcome_specs)) {
 spec <- outcome_specs[[key]]
 input <- d
 if(spec$analysis_type=='binary') input[[spec$primary_outcome]] <- rbinom(n,1,0.25) else {
  input[[spec$raw_outcome]] <- exp(rnorm(n,4,0.3))
  input[[spec$primary_outcome]] <- log(input[[spec$raw_outcome]])
 }
 a <- prepare_analysis_data(input,spec)
 run <- create_mice_object(a,spec,m=2L,maxit=2L)
 stopifnot(all(run$predictor_matrix[,'SEQN']==0),all(run$predictor_matrix[,'SDMVPSU']==0))
 if(!is.null(spec$raw_outcome)) stopifnot(all(run$predictor_matrix[,spec$raw_outcome]==0))
 completed <- complete_imputations(run$imp,spec)
 result <- fit_primary_model3(completed,spec)
 all_results[[key]] <- result
 if (!is.null(run$imp$loggedEvents)) {
   cat("MICE diagnostic events for", key, "\n")
   print(unique(run$imp$loggedEvents[, c("dep", "meth", "out")]))
 }
 stopifnot(nrow(result$exposure)==1L, is.finite(result$exposure$beta),
  is.finite(result$exposure$P_value), result$exposure$P_value>=0, result$exposure$P_value<=1,
  result$exposure$CI_lower<result$exposure$CI_upper)
 bad <- input; bad$sleep_anchored_mvpa_phase_h[1] <- NA_real_
 stopifnot(inherits(try(prepare_analysis_data(bad,spec),silent=TRUE),'try-error'))
 bad <- input; bad$SEQN[2] <- bad$SEQN[1]
 stopifnot(inherits(try(prepare_analysis_data(bad,spec),silent=TRUE),'try-error'))
 if(spec$analysis_type!='binary') {
  bad <- input;bad[[spec$primary_outcome]][1] <- 0
  stopifnot(inherits(try(prepare_analysis_data(bad,spec),silent=TRUE),'try-error'))
 }
}
cat('Synthetic MICE and all five survey outcome tests passed.\n')

combined <- combine_exposure_results(all_results)
stopifnot(nrow(combined)==5L,is.finite(combined$OR[1]),
 all(is.na(combined$OR[-1])), is.na(combined$percent_difference[1]),
 all(is.finite(combined$percent_difference[-1])))
cat('Combined binary and continuous output schema tests passed.\n')
