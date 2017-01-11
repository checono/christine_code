*************************************************************************
*Evaluation of BPCI Model 1
*PAC analysis - statistics

*************************************************************************

clear all
set more off
cap log close
set logtype text
global Path "S:\dza710\BPCI\PAC"
cd ${Path}
*Ado directory
*sysdir set PERSONAL dza710:\ado\
*or
adopath + "S:\Shared\alberto\ado"

log using "${Path}\logs\PAC_stats_092215.txt", replace


*************************
*Descriptive Statistics
**************************
*All Sample 

use Data\pac_analytic, clear

keep painNQF pain_sleep mob_assist  falls_30days selfcare_comp HBPCI post qtr
gen base=post==0
gen q7=qtr==16
save Data\pac_stats_input, replace


use Data\pac_stats_input, clear
preserve
foreach t in base post  q7 {
	desc, short

	foreach z of varlist   painNQF pain_sleep mob_assist  falls_30days selfcare_comp {
		desc, short
		collapse (mean)`z'_1=`z' (sd)`z'_2=`z' 	(count) `z'_3=`z'  if (`t'==1), by(HBPCI `t')
		save "results\bpci_`z'_table1_`t'", replace

		* reshaping outcome  for tables
		use "results\bpci_`z'_table1_`t'",clear
		desc
		reshape long `z'_@, i(HBPCI) j(stat) 
		label define stat 1"mean" 2"sd" 3"N"  4"N hospitals"  5"N hospitals/quarters"
		label values stat stat
		desc
		gen str bpci_type_str="bpci_treat" if HBPCI==1
		replace bpci_type_str="bpci_cont" if HBPCI==0
		drop HBPCI
		rename bpci_type_str bpci_type
		reshape wide `z'_@, i(stat) j(bpci_type) string
		gen str outcome="`z'"
		rename `z'_* *
		order outcome stat bpci* 
		rename bpci* bpci*_`t'
		save "results\bpci_`z'_table1_`t'", replace
		restore, preserve
		desc, short
	}

	desc, short
}



* combine results for bpci
restore
desc, short

foreach t in base post  q7 {

use "results\bpci_falls_30days_table1_`t'", clear
append using "results\bpci_mob_assist_table1_`t'"
append using  "results\bpci_painNQF_table1_`t'"
append using "results\bpci_pain_sleep_table1_`t'"
append using "results\bpci_selfcare_comp_table1_`t'"

tempfile bpci_append_`t'
save `bpci_append_`t'', replace
}

use `bpci_append_base', clear
merge 1:1 stat outcome using `bpci_append_post'
drop _merge
merge 1:1 stat outcome using `bpci_append_q7'
label drop stat
label define stat 1"mean" 2"sd" 3"N of episodes"  4"N hospitals"  5"N hospitals/quarters"
label values stat stat
sort outcome stat
drop _merge base post q7
 foreach x of varlist bpci* {
  label var `x' " "
  }
 
order outcome stat bpci_treat_base bpci_cont_base bpci_treat_post bpci_cont_post bpci_treat_q7 bpci_cont_q7
list, separator(3) abb(16)

save "results\table1_bpci", replace


*Active vs Controls

use Data\pac_analytic_actives, clear

keep painNQF pain_sleep mob_assist  falls_30days selfcare_comp HBPCI post qtr
gen base=post==0
gen q7=qtr==16
save Data\pac_stats_input_act, replace


use Data\pac_stats_input_act, clear
preserve
foreach t in base post  q7 {
	desc, short

	foreach z of varlist   painNQF pain_sleep mob_assist  falls_30days selfcare_comp {
		desc, short
		collapse (mean)`z'_1=`z' (sd)`z'_2=`z' 	(count) `z'_3=`z'  if (`t'==1), by(HBPCI `t')
		save "results\bpci_`z'_table1_`t'_a", replace

		* reshaping outcome  for tables
		use "results\bpci_`z'_table1_`t'_a",clear
		desc
		reshape long `z'_@, i(HBPCI) j(stat) 
		label define stat 1"mean" 2"sd" 3"N"  4"N hospitals"  5"N hospitals/quarters"
		label values stat stat
		desc
		gen str bpci_type_str="bpci_act" if HBPCI==1
		replace bpci_type_str="bpci_cont" if HBPCI==0
		drop HBPCI
		rename bpci_type_str bpci_type
		reshape wide `z'_@, i(stat) j(bpci_type) string
		gen str outcome="`z'"
		rename `z'_* *
		order outcome stat bpci* 
		rename bpci* bpci*_`t'
		save "results\bpci_`z'_table1_`t'_a", replace
		restore, preserve
		desc, short
	}

	desc, short
}



* combine results for bpci
restore
desc, short

foreach t in base post  q7 {


use "results\bpci_falls_30days_table1_`t'_a", clear
append using "results\bpci_mob_assist_table1_`t'_a"
append using  "results\bpci_painNQF_table1_`t'_a"
append using "results\bpci_pain_sleep_table1_`t'_a"
append using "results\bpci_selfcare_comp_table1_`t'_a"

tempfile bpci_append_`t'_a
save `bpci_append_`t'_a', replace
}

use `bpci_append_base_a', clear
merge 1:1 stat outcome using `bpci_append_post_a'
drop _merge
merge 1:1 stat outcome using `bpci_append_q7_a'
label drop stat
label define stat 1"mean" 2"sd" 3"N of episodes"  4"N hospitals"  5"N hospitals/quarters"
label values stat stat
sort outcome stat
drop _merge base post q7
 foreach x of varlist bpci* {
  label var `x' " "
  }
 
order outcome stat bpci_act_base bpci_cont_base bpci_act_post bpci_cont_post bpci_act_q7 bpci_cont_q7
list, clean  abb(16)

save "results\table1_bpci_a", replace

*Exits vs Controls
use Data\pac_analytic_exits, clear
keep painNQF pain_sleep mob_assist  falls_30days selfcare_comp HBPCI post qtr
gen base=post==0
gen q7=qtr==16
save Data\pac_stats_input_exi, replace

use Data\pac_stats_input_exi, clear
preserve
foreach t in base post  q7 {
	desc, short

	foreach z of varlist   painNQF pain_sleep mob_assist  falls_30days selfcare_comp {
		desc, short
		collapse (mean)`z'_1=`z' (sd)`z'_2=`z' 	(count) `z'_3=`z'  if (`t'==1), by(HBPCI `t')
		save "results\bpci_`z'_table1_`t'_e", replace

		* reshaping outcome  for tables
		use "results\bpci_`z'_table1_`t'_e",clear
		desc
		reshape long `z'_@, i(HBPCI) j(stat) 
		label define stat 1"mean" 2"sd" 3"N"  4"N hospitals"  5"N hospitals/quarters"
		label values stat stat
		desc
		gen str bpci_type_str="bpci_exits" if HBPCI==1
		replace bpci_type_str="bpci_cont" if HBPCI==0
		drop HBPCI
		rename bpci_type_str bpci_type
		reshape wide `z'_@, i(stat) j(bpci_type) string
		gen str outcome="`z'"
		rename `z'_* *
		order outcome stat bpci* 
		rename bpci* bpci*_`t'
		save "results\bpci_`z'_table1_`t'_e", replace
		restore, preserve
		desc, short
	}

	desc, short
}

* combine results for bpci
restore
desc, short

foreach t in base post  q7 {

use "results\bpci_falls_30days_table1_`t'_e", clear
append using "results\bpci_mob_assist_table1_`t'_e"
append using  "results\bpci_painNQF_table1_`t'_e"
append using "results\bpci_pain_sleep_table1_`t'_e"
append using "results\bpci_selfcare_comp_table1_`t'_e"

tempfile bpci_append_`t'_e
save `bpci_append_`t'_e', replace
}

use `bpci_append_base_e', clear
merge 1:1 stat outcome using `bpci_append_post_e'
drop _merge
merge 1:1 stat outcome using `bpci_append_q7_e'
label drop stat
label define stat 1"mean" 2"sd" 3"N of episodes"  4"N hospitals"  5"N hospitals/quarters"
label values stat stat
sort outcome stat
drop _merge base post q7
 foreach x of varlist bpci* {
  label var `x' " "
  }
 
order outcome stat bpci_exits_base bpci_cont_base bpci_exits_post bpci_cont_post bpci_exits_q7 bpci_cont_q7
list, clean  abb(16)

save "results\table1_bpci_e", replace


*Number of claims with clm_thru_dt between 01/01/11 - 12/31/14
*Determining the clm_thru_dt and the clm_from_dt of the claims used in the DID analysis
*Theoretically, we are only using claims with a SNF assessment (within 30 days 
*of ip discharge) between 01/01/11 and 
use Data\pac_analytic, clear
sum clm_from_dt clm_thru_dt, format
sum clm_from_dt clm_thru_dt if clm_thru_dt<=(td(31dec2014))
tab1 HBPCI* if clm_thru_dt<=(td(31dec2014))
tab1 HCONT* if clm_thru_dt<=(td(31dec2014))

use "Data\did_2015_04_msr15_wADDED_DATE.dta", clear

sum clm_thru_dt clm_from_dt
sum clm_from_dt clm_thru_dt if clm_thru_dt<=(td(31dec2014))
tab1 HBPCI* if clm_thru_dt<=(td(31dec2014))
tab1 HCONT* if clm_thru_dt<=(td(31dec2014))



