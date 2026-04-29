# Stata Coding Instructions
# Based on: DIME Analytics Stata Style Guide
# (worldbank.github.io/dime-data-handbook/coding.html)
# and project-specific conventions for impact evaluation & survey data work

applyTo: "**/*.do"

---

## 1. Core principle

Good Stata code has three elements: **structure** (file and folder organisation),
**syntax** (readable, explicit commands), and **style** (spacing, naming,
comments). Code must not only produce correct results — it must be readable and
replicable by a colleague who has never seen it before. Always write code as if
a stranger will read it.

---

## 2. Boilerplate — start of every do-file

Every do-file must open with `ieboilstart` or the manual equivalent. Never skip
this — it standardises Stata version, memory, and settings across all machines.

```stata
* Preferred — using ietoolkit
ieboilstart, version(18.0)
`r(version)'

* Alternative — manual boilerplate
version 18
clear all
set more off
set varabbrev off
macro drop _all
```

---

## 3. Do-file header

Every do-file must begin with a header block immediately after the boilerplate:

```stata
/*******************************************************************************
  Project:    [Project name]
  Task:       [Clean / Construct / Analysis]
  Author:     [Name]
  Date:       [YYYY-MM-DD]
  Modified:   [YYYY-MM-DD]

  Inputs:     $raw/survey_data.dta
  Outputs:    $clean/survey_clean.dta

  ID var:     hhid
  Notes:      [Randomisation seed, key decisions, caveats]
*******************************************************************************/
```

---

## 4. File paths — never hardcode, never use cd

Set all paths as globals once in the master do-file. Reference globals everywhere
else. Never use `cd`. Never write an absolute path inside a task do-file.

```stata
* In 0_master.do only
global root    "C:/Users/username/project"    // each user sets this once
global data    "$root/DataWork/Data"
global raw     "$data/Raw"
global clean   "$data/Clean"
global final   "$data/Final"
global code    "$root/DataWork/Code"
global output  "$root/DataWork/Output"

* In task do-files — reference globals only
use "$raw/survey_data.dta", clear
save "$clean/survey_clean.dta", replace
```

---

## 5. Naming conventions

- Use **snake_case** for all variable names, locals, and globals
- Never abbreviate variable names — write the full name every time
- Command abbreviations must be at least **3 characters**
  (only exceptions: `tw` for twoway, `di` for display)
- Keep `set varabbrev off` — Stata's variable abbreviation causes silent bugs

```stata
* GOOD
local household_income = r(mean)
generate employed_dummy = 1
replace  employed_dummy = 0 if _merge == 2

* BAD — abbreviations hide intent and cause errors
local hhinc = r(mean)
gen emp = 1
rep emp = 0 if _merge == 2
```

---

## 6. Labelling — always, immediately

Label every variable and every value immediately after creating or modifying it.
Never leave unlabelled variables in any dataset. Define value labels once and
reuse them.

```stata
* Variable labels
label variable employed      "=1 if employed at time of survey"
label variable coffee_area   "Total area planted with coffee (acres)"
label variable age_final     "Age in years (calculated or self-reported)"

* Value labels — define once, apply everywhere
label define yesno     0 "No"  1 "Yes"
label define dk_refuse -99 "Don't know"  -66 "Refused/N/A"  -88 "Other"

label values employed      yesno
label values coffee_yn     yesno
label values birth_year    dk_refuse
```

**Special survey codes — always preserve and label:**

| Code  | Meaning                  |
|-------|--------------------------|
| `-99` | Don't know / can't tell  |
| `-66` | Refused / not applicable |
| `-88` | Other (specify)          |

---

## 7. White space and indentation

Use white space to align related statements. Indent loop and conditional bodies
**4 spaces** — never tabs (tabs render differently across platforms and GitHub).

```stata
* Aligned assignments — signal the central object
generate employed      = 1
replace  employed      = 0  if _merge == 2
label    variable employed  "Person exists in employment data"

* Loops — 4-space indent, closing brace at same level as foreach
foreach var of varlist coffee_area kiboko_kg cherry_kg {
    replace `var' = . if `var' == -99
    replace `var' = . if `var' == -66
    label variable `var' "`var' (missing codes removed)"
}

* Nested loops — 8-space indent
foreach region in north south east {
    foreach crop in coffee maize {
        summarize yield if region == "`region'" & crop == "`crop'"
    }
}
```

---

## 8. Line breaks for long commands

Break long commands across lines using `///`. Indent continuation lines
4 spaces under the opening command.

```stata
regress outcome_var treatment_var covariate_1 covariate_2 ///
    covariate_3 covariate_4 i.region,                      ///
    robust cluster(village_id)
```

---

## 9. Assertions and data validation

Use `assert` to validate assumptions before acting on data. Use `isid` to
confirm unique identifiers. Never `drop` without first confirming what will
be dropped.

```stata
* Confirm unique ID before any merge
isid hhid

* Assert clean values before recoding
assert inlist(coffee_yn, 0, 1, .)
assert birth_year > 1900 if !missing(birth_year) & birth_year != -99 & birth_year != -66

* Always inspect merge results
merge 1:1 hhid using "$clean/treatment.dta"
tabulate _merge
assert _merge == 3    // remove this line if unmatched records are expected
drop _merge
```

---

## 10. Age and date calculations

Never pass raw survey date fields into date functions without guarding against
missing values, refused codes (`-66`), and don't-know codes (`-99`). Failing
to do so produces errors like `cannot convert '--' to a date`.

```stata
* CORRECT — guard every component before calculating
generate age_final = .

replace age_final = round(                                      ///
    (td(01jan2025) - mdy(birth_month, birth_day, birth_year))   ///
    / 365.25, 1)                                                ///
    if !missing(birth_year, birth_month, birth_day)             ///
    & birth_year  != -99 & birth_year  != -66                   ///
    & birth_month != -99 & birth_month != -66                   ///
    & birth_day   != -99 & birth_day   != -66

* Fall back to self-reported age where calculated age is missing
replace age_final = age_approx                                  ///
    if missing(age_final)                                       ///
    & !missing(age_approx)                                      ///
    & age_approx != -99 & age_approx != -66

label variable age_final "Age in years (calculated or self-reported)"

* WRONG — will error if any component is -99, -66, or missing
generate age_wrong = (today() - mdy(birth_month, birth_day, birth_year)) / 365.25
```

---

## 11. Randomisation

Always set and document a random seed before any randomisation. Record the seed
in the do-file header and in the project README.

```stata
* Document seed in header: Seed = 20240415
set seed 20240415
generate rand_draw = runiform()
sort rand_draw hhid        // sort on hhid as tiebreaker for reproducibility
generate treatment = (_n <= round(_N * 0.5))

label define treatment_lbl 0 "Control" 1 "Treatment"
label values treatment treatment_lbl
label variable treatment "Treatment assignment (randomised)"
```

---

## 12. Regression output

Always use robust standard errors. Export all tables programmatically using
`esttab` (from `estout`) or `outreg2`. Never copy-paste results manually.

```stata
* Run regression with robust SEs
regress outcome_var treatment controls, robust
estimates store reg_main

* Export to LaTeX
esttab reg_main using "$output/tables/main_results.tex", ///
    replace                                               ///
    se                                                    ///
    star(* 0.1 ** 0.05 *** 0.01)                         ///
    label                                                 ///
    booktabs                                              ///
    title("Main Results")
```

---

## 13. DIME packages — prefer over manual equivalents

Install: `ssc install ietoolkit` and `ssc install iefieldkit`

| Task                          | Command        | Package    |
|-------------------------------|----------------|------------|
| Standardise settings          | `ieboilstart`  | ietoolkit  |
| Set up folder structure       | `iefolder`     | ietoolkit  |
| Balance / attrition tables    | `iebaltab`     | ietoolkit  |
| Identify & fix duplicate IDs  | `ieduplicates` | iefieldkit |
| Variable codebook             | `iecodebook`   | iefieldkit |
| High-frequency data checks    | `iehfc`        | iefieldkit |

---

## 14. Folder structure — iefolder standard

```
DataWork/
├── Data/
│   ├── Raw/           ← Never modify after receipt — treat as read-only
│   ├── Clean/         ← One cleaned file per unit of observation
│   ├── Constructed/   ← Analysis variables constructed and merged
│   └── Final/         ← Analysis-ready dataset
├── Code/
│   ├── 0_master.do    ← Runs entire pipeline from raw to outputs
│   ├── 1_clean/
│   ├── 2_construct/
│   └── 3_analysis/
├── Output/
│   ├── Tables/
│   └── Figures/
└── Documentation/
```

`0_master.do` must reproduce all outputs from raw data in a single run with
no manual steps.

---

## 15. What to avoid

- Do not use `cd` — use `$globals` for all paths
- Do not abbreviate commands below 3 characters or abbreviate variable names
- Do not generate variables without immediately labelling them
- Do not use `encode` without checking for existing value labels first
- Do not `drop` variables or observations without a preceding `assert` or
  `keep` to confirm what is being removed
- Do not leave commented-out code blocks without explaining why they remain
- Do not commit PII (names, phone numbers, GPS) to GitHub or include in
  output files
- Do not copy-paste regression results — always export programmatically

---

## 16. References

- DIME Analytics Stata Style Guide: https://worldbank.github.io/dime-data-handbook/coding.html
- DIME Wiki — Stata Coding Practices: https://dimewiki.worldbank.org/Stata_Coding_Practices
- DIME Standards: https://github.com/worldbank/dime-standards
- ietoolkit: https://github.com/worldbank/ietoolkit
- iefieldkit: https://github.com/worldbank/iefieldkit
