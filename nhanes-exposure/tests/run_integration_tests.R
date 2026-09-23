# Generated 60-second epochs test real input parsing and validity thresholds.
source('R/03_derive_sleep_midpoint.R')
source('R/04_derive_mvpa_phase.R')
source('R/05_derive_sleep_anchored_phase.R')
local({
 minute_file <- tempfile(fileext='.csv')
 sleep_file <- tempfile(fileext='.csv')
 on.exit(unlink(c(minute_file,sleep_file)))
 n <- 6L*1440L
 d <- data.frame(timenum=as.numeric(as.POSIXct('2020-01-01',tz='UTC'))+60*(0:(n-1)),
  ACC=0,invalidepoch=0)
 day <- rep(1:6,each=1440)
 minute <- rep(0:1439,6)
 d$ACC[minute==720] <- 100
 d$ACC[minute==721] <- 99.99
 d$invalidepoch[day==6 & minute>=959] <- 1
 data.table::fwrite(d,minute_file)
 a <- derive_mvpa_summary(minute_file)
 stopifnot(a$n_valid_days==5L,a$observed_total_mvpa_minutes==5L,
  abs(a$habitual_mvpa_phase_h-(720.5/60))<1e-8,
  abs(a$mvpa_resultant_length_R-1)<1e-8)
 nights <- data.frame(ID=rep('SYNTHETIC',3),sleeponset=23,wakeup=31,
  SptDuration=8,SleepDurationInSpt=7,number_sib_sleepperiod=10,acc_available=TRUE)
 data.table::fwrite(nights,sleep_file)
 s <- derive_sleep_summary(sleep_file,'SYNTHETIC')
 phase <- derive_primary_phase(a,s)
 stopifnot(s$n_valid_nights==3L,abs(s$habitual_sleep_midpoint_h-3)<1e-8,
  phase$include_primary,abs(phase$phase_h-(720.5/60-3))<1e-8)
 a$mvpa_resultant_length_R <- 0.2999
 stopifnot(!derive_primary_phase(a,s)$include_primary)
 d$timenum[2] <- d$timenum[1]
 data.table::fwrite(d,minute_file)
 stopifnot(inherits(try(derive_mvpa_summary(minute_file),silent=TRUE),'try-error'))
})
cat('Synthetic minute-file, sleep-file and QC integration tests passed.\n')
