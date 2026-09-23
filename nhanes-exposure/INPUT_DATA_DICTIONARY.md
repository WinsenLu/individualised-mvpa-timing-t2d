# Input and output data dictionary

## 1. Raw NHANES PAX80 accelerometry

The study exposure pipeline starts from participant-specific NHANES PAX80 raw accelerometer archives.

Expected sensor file header:

```text
HEADER_TIMESTAMP,X,Y,Z
```

Expected raw columns:

| Column | Meaning |
|---|---|
| `HEADER_TIMESTAMP` | Raw accelerometer timestamp |
| `X` | x-axis acceleration |
| `Y` | y-axis acceleration |
| `Z` | z-axis acceleration |

Study settings:

| Setting | Value |
|---|---|
| Sampling frequency | 80 Hz |
| Acceleration unit supplied to GGIR | g |
| Time format | `%Y-%m-%d %H:%M:%OS` |
| Processing time zone | UTC |
| Sensor location | wrist |
| GGIR version | 3.0.0 |

## 2. GGIR minute-level activity output

The exposure code reads the GGIR Part 5 raw-level export under `meta/ms5.outraw`.

Required columns:

| Column | Role |
|---|---|
| `timenum` | Epoch time |
| `ACC` | 60-s ENMO value used for MVPA classification |
| `invalidepoch` | Epoch validity indicator |

The script verifies that the exported series is at 60-s resolution.

Derived fields include:

- `date`;
- `minute_of_day` (0–1439);
- `valid_epoch`;
- valid-day status.

A valid day contains at least 16 h of valid epochs.

## 3. GGIR sleep output

Required file:

```text
part4_nightsummary_sleep_cleaned.csv
```

Required study variables:

| Column | Role |
|---|---|
| `ID` | Participant identifier used to select the participant's rows |
| `sleeponset` | Sleep onset in continuous decimal hours |
| `wakeup` | Final wake in continuous decimal hours |
| `SptDuration` | Sleep-period duration used for night-level sanity checks |
| `SleepDurationInSpt` | Sleep duration used in participant-level QC |
| `number_sib_sleepperiod` | Number of sleep periods used in participant-level QC |

If `acc_available` is present, the study script retains nights where the value is missing or indicates available accelerometer data.

The code requires `SleepDurationInSpt` and `number_sib_sleepperiod` because both are part of the prespecified primary QC criteria. It does not silently substitute another variable or skip the sleep-period criterion.

## 4. Habitual MVPA distribution

For each valid day, valid 60-s epochs are retained.

MVPA:

```text
ACC >= 100 mg
```

For each minute-of-day position, the code calculates:

| Derived variable | Meaning |
|---|---|
| `valid_observations` | Number of valid observations at that minute position across valid days |
| `mvpa_minutes` | Number of valid observations meeting the MVPA threshold |
| `clock_hour_midpoint` | `(minute_of_day + 0.5)/60` |
| `mvpa_probability` | `mvpa_minutes / valid_observations` when observed |

The primary circular centroid uses `mvpa_minutes` as weights.

## 5. Participant-level exposure output

| Variable | Meaning |
|---|---|
| `habitual_mvpa_phase_h` | Circular centroid \(M\) of the habitual MVPA distribution |
| `mvpa_resultant_length_R` | Resultant vector length for the MVPA distribution |
| `habitual_sleep_midpoint_h` | Circular habitual sleep midpoint \(S\) |
| `sleep_midpoint_resultant_length_R` | Concentration of nightly sleep midpoints |
| `sleep_anchored_mvpa_phase_raw_h` | `(M-S) mod 24` before primary QC masking |
| `sleep_anchored_mvpa_phase_h` | Primary exposure, retained only when all QC criteria pass |
| `include_primary` | Whether all exposure-related QC criteria are satisfied |
| `exclusion_reason` | Semicolon-separated exposure-QC exclusion reason(s) |

No participant-level output is included in the repository.
