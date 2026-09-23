# Artificial follow-up examples exercise censoring and categorical references.
source('R/00_utils.R')
source('R/01_prepare_survival_data.R')
source('R/02_multiple_imputation.R')
source('R/03_model_specifications.R')
source('R/04_fit_primary_cox_models.R')
set.seed(731)
n <- 600L
d <- data.frame(Baseline_Date = rep('2015-01-01', n),
  UK_Biobank_assessment_centre = rep(c('England','Scotland','Wales'), length.out=n),
  Date_of_death=rep(NA_character_,n), Date_lost_to_follow.up=rep(NA_character_,n),
  Exposure=ordered(rep(paste0('Q',1:5),length.out=n)),
  Phase_angle_hour=runif(n,8,16), stringsAsFactors=FALSE)
d[['Date_E11_first_reported_.non.insulin.dependent_diabetes_mellitus.']] <-
  as.character(as.Date('2015-01-01') + sample(100:4000,n,replace=TRUE))
cat_vars <- c('Sex','Occupation','Smoking','Ethnic','Qualifications','Hypertension',
  'Dyslipidemia','Depression','Accelerometer_season','CVD','Family_history_diabetes')
for (v in cat_vars) d[[v]] <- sample(c('A','B'),n,replace=TRUE)
for (v in c('Age','TDI','Alcohol','Healthy_diet_score','Coffee_tea','MVPA_daily_min','Average_Sleep_Duration','R_MVPA'))
  d[[v]] <- runif(n,1,10)
d$R_MVPA <- runif(n,0.3,1)
d$Date_of_death[1] <- '2015-06-01'
d[['Date_E11_first_reported_.non.insulin.dependent_diabetes_mellitus.']][1:4] <-
  c('2016-01-01','2014-01-01','2022-05-31','2023-03-31')
a <- prepare_survival_data(d)
stopifnot(nrow(a)==n-1L, a$status[1]==0L,
  as.character(a$Followup_End[1])=='2015-06-01',
  a$status[2]==1L, a$status[3]==1L,
  !is.ordered(a$Exposure), levels(a$Exposure)[1]=='Q1',
  length(primary_model_formulas)==8L)
# Covariate missingness exercises actual MICE and Rubin pooling.
a$TDI[seq(10,nrow(a),by=13)] <- NA_real_
imp <- create_mice_object(a,m=2L,maxit=2L,seed=381L)
out <- fit_all_primary_models(imp,primary_model_formulas)
stopifnot(nrow(out$exposure_terms)==20L,
 all(is.finite(out$exposure_terms$HR)), all(out$exposure_terms$HR>0),
 all(is.finite(out$exposure_terms$conf_low)),
 all(out$exposure_terms$conf_low<=out$exposure_terms$HR),
 all(out$exposure_terms$conf_high>=out$exposure_terms$HR),
 !any(grepl('Exposure[.]L',out$exposure_terms$term)))
cat('Synthetic censoring, MICE and eight Cox model tests passed.\n')

stopifnot(inherits(try(parse_date_vector("not-a-date"), silent=TRUE), "try-error"))
