clear
set more off 

capture program drop model_ols   
program define model_ols
	args dep 

			reg `dep' i.HBPCI i.post i.HBPCI#i.year  i.year i.hpid, vce(cluster hosp_qrt)

			display "*****************************"
			display "REHASH of YEAR 1 & 2 WITH YEAR FE"
			display "*****************************"
						*DID CoEF & Sig Test for PY1 & PY2
							margins r.HBPCI, over(r.year) noestimcheck //post
								mat didpy_tble = r(table)

								*mat list didpy_tble
							*PY 1 & PY2 Values
							margins HBPCI, over(year) noestimcheck //post
								mat pyval_tble = r(table)
								
							*PY 1 & PY2 Values
							margins HBPCI, over(r.year) contrast(marginswithin effects) noestimcheck //post
								mat py_tble = r(table)
			/*
								
			display "*****************************"
			display "REHASH OF POST/PRE WITH YEAR FE"
			display "*****************************"	
							margins r.HBPCI, over(r.post) noestimcheck //post
								mat did_tble = r(table)
								*mat list did_tble

							*PP CoEF & Sig Test
							margins HBPCI, over(r.post) contrast(marginswithin effects) noestimcheck //post
								mat pp_tble = r(table)
								*mat list pp_tble
						
							*PP Values
							margins HBPCI, over(post) noestimcheck //post
								mat ppval_tble = r(table)	
			*/
end






log using "S:\Shared\CHerlihy\logs\examine_msr22_20160502", replace
use "S:\Shared\AShangraw\data\2015_10\compressed\DID_2015_10_MSR22_SPLITv3.dta", clear

*global providers "310070 010139 310075 390102 440161 310038 100008  310009 310076  330106"

preserve
disp "310070"
keep if prvdr_num == "310070"| CONT310070 == 1

*Adjust for medical CPI 
foreach vari in analysis_variable_all_std{

			replace `vari' = `vari' * 0.941 if years == "2011"
			replace `vari' = `vari' * 0.976 if years== "2012"
			replace `vari' = `vari' * 1.000 if years == "2013"
			replace `vari' = `vari' * 1.024 if years == "2014"
			replace `vari' = `vari' * 1.056 if years == "2015"
		}

			
collapse (mean) analysis_variable_all_std, by(HBPCI quarter)
list
outsheet using S:\Shared\CHerlihy\data\msr22_examine\DATA1.txt, replace
restore

preserve
disp "310038"
keep if prvdr_num == "310038" | CONT310038 == 1

*Adjust for medical CPI 
foreach vari in analysis_variable_all_std{

			replace `vari' = `vari' * 0.941 if years == "2011"
			replace `vari' = `vari' * 0.976 if years== "2012"
			replace `vari' = `vari' * 1.000 if years == "2013"
			replace `vari' = `vari' * 1.024 if years == "2014"
			replace `vari' = `vari' * 1.056 if years == "2015"
		}

			
collapse (mean) analysis_variable_all_std, by(HBPCI quarter)
list
outsheet using S:\Shared\CHerlihy\data\msr22_examine\DATA2.txt, replace
restore

preserve
foreach vari in analysis_variable_all_std{

			replace `vari' = `vari' * 0.941 if years == "2011"
			replace `vari' = `vari' * 0.976 if years== "2012"
			replace `vari' = `vari' * 1.000 if years == "2013"
			replace `vari' = `vari' * 1.024 if years == "2014"
			replace `vari' = `vari' * 1.056 if years == "2015"
		}

			
collapse (mean) analysis_variable_all_std, by(HBPCI quarter)
list
outsheet using S:\Shared\CHerlihy\data\msr22_examine\DATA3.txt, replace
restore


preserve
keep if HBPCI == 1
foreach vari in analysis_variable_all_std{

			replace `vari' = `vari' * 0.941 if years == "2011"
			replace `vari' = `vari' * 0.976 if years== "2012"
			replace `vari' = `vari' * 1.000 if years == "2013"
			replace `vari' = `vari' * 1.024 if years == "2014"
			replace `vari' = `vari' * 1.056 if years == "2015"
		}

			
collapse (mean) analysis_variable_all_std, by(prvdr_num quarter)
list
outsheet using S:\Shared\CHerlihy\data\msr22_examine\DATA4.txt, replace
restore

*****GENERATE "year" VALUES

	gen active=(HBPCIC==1 | HCONTC==1)
	gen exits=(HBPCIX==1 | HCONTX==1)
	gen expan=(HBPCIE==1 | HCONTE==1)
	gen targ=(HBPCIT==1 | HCONTT==1)
	gen PHC=(HBPCIPHC==1 | HCONTPHC==1)
	gen all=1
	
	global cohorts "active exits expan targ PHC all"
	
	foreach x of global cohorts{
		preserve
		keep if `x' == 1
		disp "Cohort selected: `x'"

		foreach vari in analysis_variable_all_std{

			replace `vari' = `vari' * 0.941 if years == "2011"
			replace `vari' = `vari' * 0.976 if years== "2012"
			replace `vari' = `vari' * 1.000 if years == "2013"
			replace `vari' = `vari' * 1.024 if years == "2014"
			replace `vari' = `vari' * 1.056 if years == "2015"
			}
	
		capture drop year
		gen year = 0
		replace year = 1 if inlist(qtr, 10,11,12,13) & !inlist(prvdr_num,"170183","340049","050708","520196","050697")
		replace year = 1 if inlist(qtr, 13) & inlist(prvdr_num,"170183","340049","050708","520196","050697")
		replace year = 2 if inlist(qtr,14,15,16,17) //& !inlist(prvdr_num,"170183","340049","050708","520196","050697")
	
		drop if quarter > "2015-1"
		
		local v analysis_variable_all_std
		model_ols `v'

		restore
	}

log close 



global meas = "mpayinp"
			rename analysis_variable_all ${meas}
			rename analysis_variable_nhp ${meas}_nhp
			gen ${meas}_hp = ${meas} - ${meas}_nhp
			gen ${meas}_hp_std = analysis_variable_all_std
			gen opPay = operating_payment_discount
			replace opPay = 0 if missing(operating_payment_discount)
			gen ${meas}_hp_ndsct = ${meas}_hp + opPay
			gen ${meas}_ndsct = ${meas} + opPay
			gen ${meas}_hp_std_wdsct = ${meas}_hp_std - opPay
			gen yrz = substr(quarter,1,4)
			
foreach vari of ${meas}_hp_std_wdsct{
			
			replace `vari' = `vari' * 0.941 if yrz == "2011"
			replace `vari' = `vari' * 0.976 if yrz == "2012"
			replace `vari' = `vari' * 1.000 if yrz == "2013"
			replace `vari' = `vari' * 1.024 if yrz == "2014"
			replace `vari' = `vari' * 1.056 if yrz == "2015"
		}

	foreach x of global cohorts{
		preserve
		keep if `x' == 1
		disp "Cohort selected: `x'"

		capture drop year
		gen year = 0
		replace year = 1 if inlist(qtr, 10,11,12,13) & !inlist(prvdr_num,"170183","340049","050708","520196","050697")
		replace year = 1 if inlist(qtr, 13) & inlist(prvdr_num,"170183","340049","050708","520196","050697")
		replace year = 2 if inlist(qtr,14,15,16,17) //& !inlist(prvdr_num,"170183","340049","050708","520196","050697")
	
		drop if quarter > "2015-1"
		
		collapse (mean) ${meas}_hp_std_wdsct, by(HBPCI year)
		list
		outsheet using "S:\Shared\CHerlihy\data\msr22_examine\DATA_`x'.txt", replace

		restore
	}

log close 


foreach num of global providers{
	preserve
	keep if prvdr_num == "`num'"
	disp "`num'"
	tab quarter if prvdr_num == "`num'", summarize(analysis_variable_all_std)
	save "S:\Shared\CHerlihy\data\msr22_examine\out_`num'", replace
	local hospitalID = "hospitalID" + "`num'"
	gen `hospitalID' = "`num'"
	restore
	
	}
	
local mFiles : dir "S:\Shared\CHerlihy\data\msr22_examine\" files "*dta"

clear 
foreach v of local mFiles{
                append using "S:\Shared\CHerlihy\data\msr22_examine\`v'"
}

save "S:\Shared\CHerlihy\data\msr22_examine\out_AGG", replace 


