version 19
clear all
set more off

/*
Goal: To learn how to use Positron AI assistance to write Stata code and
execute it. This code includes: data loading, descriptive statistics,
regression analysis, and visualization.

Implemented steps:
1. Load exemplary data from mex-subsample
2. Summarize descriptive statistics of all variables
3. Run a regression of income on individual characteristics
4. Create a scatter plot of income vs age
5. Create a box plot of income vs education levels
6. Save regression results and figures in an Excel file
*/

* -----------------------------
* 0) Setup folders and file paths
* -----------------------------
local wbg_root "C:/Users/wb585494/WBG"
local data_input "`wbg_root'/Eduard Bukin - ai4coding-data/mex-subsample/mex-subsample.dta"
local out_dir "`wbg_root'/ai4coding-outputs"
local fig_dir "`out_dir'/figures"
local xlsx_file "`out_dir'/analysis_results.xlsx"

* Create required output folders if missing
capture mkdir "`out_dir'"
capture mkdir "`fig_dir'"

* -----------------------------
* 1) Load data from mex-subsample
* -----------------------------
capture confirm file "`data_input'"
if _rc {
    di as err "Data file not found: `data_input'"
    exit 601
}
use "`data_input'", clear

* -----------------------------
* 2) Descriptive statistics for all variables
* -----------------------------
describe
ds, has(type numeric)
local numeric_vars `r(varlist)'

* -----------------------------
* 3) Regression of income on individual characteristics
* -----------------------------
local income_var ing_tri_total
local age_var edad
local educ_var educ_cat
local controls edad hombre anios_educ formal tot_integ htrab rural
local weight_var fac_exp

* Required variables for model and plots
foreach v in `income_var' `age_var' `educ_var' `controls' {
    capture confirm variable `v'
    if _rc {
        di as err "Required variable not found: `v'"
        exit 111
    }
}

* Use survey weight if available; otherwise run unweighted
local pwopt ""
local awopt ""
capture confirm variable `weight_var'
if !_rc {
    local pwopt "[pw=`weight_var']"
    local awopt "`awopt'"
}

regress `income_var' `controls' `pwopt'

* -----------------------------
* 4) Scatter plot of income vs age
* -----------------------------
local scatter_file "`fig_dir'/scatter_`income_var'_vs_`age_var'.png"
twoway scatter `income_var' `age_var' [aw=`weight_var'], ///
    title("Scatter: income vs age") ///
    ytitle("Total quarterly individual income") ///
    xtitle("Age")
graph export "`scatter_file'", replace

* -----------------------------
* 5) Box plot of income vs education levels
* -----------------------------
local box_file "`fig_dir'/box_`income_var'_by_`educ_var'.png"
graph box `income_var', over(`educ_var') ///
    title("Box plot: income by education level") ///
    ytitle("Total quarterly individual income")
graph export "`box_file'", replace

* -----------------------------
* 6) Save outputs to Excel
* -----------------------------
putexcel set "`xlsx_file'", replace

putexcel A1 = ("Descriptive statistics (numeric variables)")
putexcel A2 = ("Variable") B2 = ("N") C2 = ("Mean") D2 = ("SD") E2 = ("Min") F2 = ("Median") G2 = ("Max")

local row = 3
foreach v of local numeric_vars {
    quietly summarize `v', detail
    putexcel A`row' = ("`v'") B`row' = (r(N)) C`row' = (r(mean)) D`row' = (r(sd)) E`row' = (r(min)) F`row' = (r(p50)) G`row' = (r(max))
    local ++row
}

local row = `row' + 2
putexcel A`row' = ("Regression: `income_var' on selected characteristics")
local row = `row' + 1
putexcel A`row' = ("Term") B`row' = ("Coef") C`row' = ("Std. Err.") D`row' = ("t") E`row' = ("P>|t|")

local row = `row' + 1
local coef_names : colnames e(b)
foreach term of local coef_names {
    putexcel A`row' = ("`term'") ///
        B`row' = (_b[`term']) ///
        C`row' = (_se[`term']) ///
        D`row' = (_b[`term'] / _se[`term']) ///
        E`row' = (2 * ttail(e(df_r), abs(_b[`term'] / _se[`term'])))
    local ++row
}

local row = `row' + 1
putexcel A`row' = ("N") B`row' = (e(N))
local row = `row' + 1
putexcel A`row' = ("R-squared") B`row' = (e(r2))
local row = `row' + 1
putexcel A`row' = ("Adj. R-squared") B`row' = (e(r2_a))

local row = `row' + 2
putexcel A`row' = ("Scatter plot")
capture confirm file "`scatter_file'"
if !_rc putexcel B`row' = picture("`scatter_file'")

local row = `row' + 20
putexcel A`row' = ("Box plot")
capture confirm file "`box_file'"
if !_rc putexcel B`row' = picture("`box_file'")
