# Copilot Instructions — Impact Evaluation & Survey Research

## Context

This is a research project focused on impact evaluation and survey data collection.
Primary tools: **Stata**, **SurveyCTO** (XLSForm), **R** (secondary), and **GitHub** for version control.
Work follows World Bank DIME Analytics coding standards where applicable.

---

## Stata conventions

- Always include a version header at the top of do-files:
  ```stata
  version 18
  clear all
  set more off
  ```
- Use `frames` for managing multiple datasets in memory
- Label all variables and values:
  ```stata
  label variable varname "Descriptive label"
  label define yesno 0 "No" 1 "Yes"
  label values varname yesno
  ```
- Use snake_case for all variable and local names
- Always use locals for paths and globals for project-wide macros:
  ```stata
  global root "C:/path/to/project"
  global data "$root/data"
  global output "$root/output"
  ```
- Prefer `quietly` for intermediate steps that don't need output
- Comment every section and non-obvious command
- Use `assert` to validate assumptions before proceeding
- Close log files in the same do-file they are opened
- Use `iebaltab`, `ietoolkit`, and `iefieldkit` for IE-specific tasks where available

---

## SurveyCTO / XLSForm conventions

- Always guard date fields against missing/refused codes before using them in calculations:
  ```
  if(${field} != '' and ${field} != -99 and ${field} != -66, ..., '')
  ```
- Use `once(format-date-time(now(), '%Y-%b-%d %H:%M:%S'))` for module timing fields
- Special codes: `-99` = don't know, `-66` = refused/not applicable, `-88` = other
- Use `calculate_here` for timing fields, `calculate` for derived variables
- Wrap all `select_one` fields in relevance before referencing their value
- Use `choice-label()` to extract labels from select fields
- Avoid nesting more than 3 `if()` statements — break into intermediate `calculate` fields

---

## R conventions (when used)

- Prefer tidyverse for data wrangling and ggplot2 for visualisation
- Use snake_case for all object names
- Always use relative paths via `here::here()`
- Use `haven` for reading Stata `.dta` files
- Document scripts with roxygen-style comments for functions

---

## General coding standards

- Never hardcode absolute paths — use globals (Stata) or `here()` (R)
- Write code that can be run by any team member from a fresh clone
- Include a header block in every script with: author, date, purpose, inputs, outputs
- Prefer explicit over implicit — avoid ambiguous syntax
- When generating regression output, always include robust standard errors
- For randomisation, always set and document the random seed

---

## Project structure

Follow DIME Analytics folder structure:
```
project/
├── data/
│   ├── raw/          # Never modified
│   ├── intermediate/ # Cleaned/merged
│   └── final/        # Analysis-ready
├── code/
│   ├── clean/
│   ├── construct/
│   └── analysis/
├── output/
│   ├── tables/
│   └── figures/
└── documentation/
```

---

## What to avoid

- Do not use `drop` without a prior `keep` or `assert` to confirm what is being dropped
- Do not use `cd` to change directories — use globals/locals for paths
- Do not generate variables without labelling them
- Do not leave commented-out code blocks without explanation
- Do not use `encode` without checking existing value labels first
