/****
Name: Jerome Davis
DLU : 15.04.06
Objective: 	conduct ttests for RA data
****/

/*

cd "\\ccwdata.org\Profiles\jda684\Documents\ttestRA" /*<-change route here*/
set more off

capture postclose mypost
tempname mypost
*postfile `mypost' str16 group str16 period str16 prvdr_num str16 ms rate se lb ub n nua pvalue pvalueUA using RAttest,replace
postfile `mypost' str16 group str16 period str16 prvdr_num str16 ms rate se lb ub n pvalue using RAttest,replace

use allQtr_150425_2014-4, clear

*	local mlist ed30 los mpayinp mpayinp_car mpayinp_dme mpayinp_hp mpayinp_nhp mpayinp_out mpaypac30 mpaypost30 pacuse readmit30 icu mort mortIHami30 mortIHhf30 mortIHpn30 readmitami30 readmithf30 readmitpn30	
*	local mlist mpaypost30 mpaypost30_car mpaypost30_dme mpaypost30_hha mpaypost30_hsp mpaypost30_inp mpaypost30_inpInd mpaypost30_inpOtr mpaypost30_out mpaypost30_snf
*	local mlist ed30
*	local mlist ed30 los mort mortIHami30 mortIHhf30 mortIHpn30 mpayinp mpayinp_car mpayinp_dme mpayinp_hp mpayinp_nhp mpayinp_out mpaypac30 mpaypost30 readmit30 readmitami30 readmithf30 readmitpn30
	local mlist ed30 icu los mort mortIHami30 mortIHhf30 mortIHpn30 mpayinp mpayinp_hp mpaypost30 readmit30 readmitami30 readmithf30 readmitpn30 mpayinpstd
	local allGroups actives exits expansive targeted phc all
	local allPeriods baseline sincebpci 10 11 12 13 14 15 16
	local allType hbpci hcont
	/****  Groups by AGGREGATE PERIOD	****/
	foreach m of local mlist{
	foreach r of local allType{
		foreach z of local allGroups{
			foreach k of local allPeriods{
				preserve
					* keep the specified aggregate period && select between BPCI and CONTROL
					keep if ms == "`m'"
					disp _N
					keep if qtr == "`k'" & prvdr_num == "`r'" 
					disp _N
					disp "`k' and `r'"					
					* select the correct provider grouping
					if "`z'" == "actives"{
						keep if cohort=="actives" 
					}
					else if "`z'" == "exits"{
						keep if cohort == "exits"
					}
					else if "`z'" == "expansive"{
						keep if cohort == "expansive"
					}
					else if "`z'" == "targeted"{
						keep if cohort == "targeted"
					}
					else if "`z'" == "phc"{
						keep if cohort == "phc"
					}
					else {
						keep if cohort == "all"
					}
					
						local crate = pdep
						local cstd  = perr*sqrt(cnt)
						local cse   = perr
						local clb   = lb
						local cub   = ub
						local cn    = cnt
*						local cnua  = uan
						local d     = ms
						local sigVal = 99
						local sigValUA = 99
						if "`k'" == "baseline"{
							*post `mypost' ("`z'") ("`k'") ("`r'") ("`d'") (`crate') (`cse') (`clb') (`cub') (`cn') (`cnua') (`sigVal') (`sigValUA')
							post `mypost' ("`z'") ("`k'") ("`r'") ("`d'") (`crate') (`cse') (`clb') (`cub') (`cn') (`sigVal')
							local bN = `cn'
*							local bNUA = `cnua'
							local bRate = `crate'
							local bStd  = `cstd'
						}
						else{
							ttesti `bN' `bRate' `bStd' `cn' `crate' `cstd', unequal
							local sigVal = `r(p)'				
*							ttesti `bNUA' `bRate' `bStd' `cnua' `crate' `cstd', unequal
*							local sigValUA = `r(p)'
*							post `mypost' ("`z'") ("`k'") ("`r'") ("`d'") (`crate') (`cse') (`clb') (`cub') (`cn') (`cnua') (`sigVal') (`sigValUA')
							post `mypost' ("`z'") ("`k'") ("`r'") ("`d'") (`crate') (`cse') (`clb') (`cub') (`cn') (`sigVal')
							}
				restore
					}
			} //END: type loop
		} //END: period loop
	} //END: GROUP LOOP
postclose `mypost'

*/

// QC calculate p-values for unadjusted rates

cd "\\ccwdata.org\Profiles\jda684\Documents\ttestRA" /*<-change route here*/
set more off

capture postclose mypost
tempname mypost
postfile `mypost' str16 group str16 period str16 prvdr_num str16 ms rate se lb ub n nua pvalue pvalueUA using RAttest3,replace

use aggAll_UA_PMRC4_MDS, clear

*	local mlist ed30 icu los mort mortIHami30 mortIHhf30 mortIHpn30 mpayinp mpayinp_car mpayinp_dme mpayinp_hp mpayinp_nhp mpayinp_out mpaypac30 mpaypost30 readmit30 readmitami30 readmithf30 readmitpn30
	local mlist icu los mort mpayinp mpayinp_hp mpaypost30 readmit30
*	local mlist ed30
	local allGroups all 310010 310038 310110 310024 310050 310070 310069 310032 310081 310019 310006 170183
	local allPeriods baseline sincebpci year1 lastQtr qtr10 qtr11 qtr12 qtr13 qtr14 qtr15 qtr16 qtr17
	
	local allType HBPCI HCONT
	/****  Groups by AGGREGATE PERIOD	****/
	foreach m of local mlist{
	foreach r of local allType{
		foreach z of local allGroups{
			foreach k of local allPeriods{
				preserve
					* keep the specified aggregate period && select between BPCI and CONTROL
					keep if ms == "`m'"
					disp _N
					keep if period == "`k'" & prvdr_num == "`r'" 
					disp _N
					disp "`k' and `r'"					
					* select the correct provider grouping
					if "`z'" == "actives"{
						keep if group == "actives" 
					}
					else if "`z'" == "exits"{
						keep if group == "exits"
					}
					else if "`z'" == "expansive"{
						keep if group == "expansive"
					}
					else if "`z'" == "targeted"{
						keep if group == "targeted"
					}
					else if "`z'" == "phc"{
						keep if group == "phc"
					}
					else if "`z'" == "all" {
						keep if group == "all"
					}
					else {
						keep if group == "`z'"
					}
					
						local crate = rate
						local cstd  = se*sqrt(n)
						local cse   = se
						local clb   = lb
						local cub   = ub
						local cn    = n
						local cnua  = n
						local d     = ms
						local sigVal = pvalue
						local sigValUA = 99
						if "`k'" == "baseline"{
							post `mypost' ("`z'") ("`k'") ("`r'") ("`d'") (`crate') (`cse') (`clb') (`cub') (`cn') (`cnua') (`sigVal') (`sigValUA')
							local bN = `cn'
							local bNUA = `cnua'
							local bRate = `crate'
							local bStd  = `cstd'
						}
						else{
							*ttesti `bN' `bRate' `bStd' `cn' `crate' `cstd', unequal
							*local sigVal = `r(p)'				
							ttesti `bNUA' `bRate' `bStd' `cnua' `crate' `cstd', unequal
							local sigValUA = `r(p)'
							post `mypost' ("`z'") ("`k'") ("`r'") ("`d'") (`crate') (`cse') (`clb') (`cub') (`cn') (`cnua') (`sigVal') (`sigValUA')
						}
				restore
					}
			} //END: type loop
		} //END: period loop
	} //END: GROUP LOOP
postclose `mypost'




