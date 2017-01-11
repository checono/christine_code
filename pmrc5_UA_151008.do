/****
Name: David Ruiz
DLU : 15.07.10
Objective:  
			UA STATS 

Data Pop:   
			all 24 BPCI hospitals and 4 matched controls for each hospitals.
			There is one control that is matched to three BPCI hospitals
			and 12 controls that are matched twice for a total of XX unique controls.
			
			--> matched 2x: 50125,70025,70028,70034,110010,250141,310009,330046,330198,340032,410007,520013
			--> matched 3x: 490057
Analyses Level:
			[ ] Provider Level
			[x] All Provider Aggregate 
			[x] Active Group
			[x] Exiting Group
			[x] Expansive Care Redesign Group
			[x] Targeted Care Redesign Group
			[ ] BPCI Only Provider Aggregate
			[x] PHC Group

Analyses Types:
			[ ] Un-Weighted UN-adjusted Rates
			[ ] Un-Weighted Risk-adjusted Rates
			[ ] Weighted UN-adjusted Rates
			[ ] Weighted Risk-adjusted Rates
			[x] Diff-in-Diffs
		
			
Output:	

****/
clear all
estimates clear
set more off
set matsize 10000
cd "S:\Shared\AShangraw\data\2015_10\compressed\merged\output"

*ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
************************* DEFINE GLOBAL MACROS *********************************
*ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
* ANALYTICAL DATA LOCATION 
global baseData "S:\Shared\AShangraw\data\2015_10\compressed\merged" 
* SET DATE
global date 151009
* SET DATASET/LOG NOTES
global note pmrc5UA
* SET DATA VERSION
global dataVer "2015_10"
* SET DATA DEPOSIT LOCATION
global  final   "S:\Shared\AShangraw\data\2015_10\compressed\merged\output"    //final data path
*dddddddddddddddddddddddddddddddddddddddddddddddddd*


*ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
************************** DEFINE LOCAL MACROS *********************************
*ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
//local  intirim "S:\Shared\David Ruiz\compressed\output\pmrc3_UG\final"  //intirim dataset path
//local  dofiles "S:\Shared\David Ruiz\testFiles\updatedCode"    					//do file data path
local  nlist 2 /*81 82 83*/ 7 /*9 10 11*/ 14 15 16 18 22


*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
*** this ado path is needed to get to the capture programs for the DID and RA 
*** estimates: createDS_Agg, createDS, and predictQuarter
*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
adopath ++ "S:\Shared\David Ruiz\ado"


*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
**** runModel PROGRAM: runs logit/reg depending on measure
*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
cap program drop runModel
program define runModel
args ms isBinary 	
	if 	`isBinary'{
			ci `ms', binomial
	}
	else{
			ci `ms'
	}
end
*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm

capture postclose `mypost'
tempname mypost 
postfile `mypost' str16 group str16 period str16 prvdr_num str16 ms rate se lb ub n pvalue using aggAll_UA_PMRC4,replace


capture log close
log using "PMRC5_UA_${date}_${note}", replace 
 
*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
*********************************** START **************************************
*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
foreach d of local nlist {
	estimates clear
		local meas=""
/*
In Hospital Mortality	2 4 5 6  --> 80 81 82 83
PSD  Mortality 2 4 5 6 --> 85 86 87 88
*/

qui{	
	if inlist(`d', 80){
		use "${baseData}/DID_${dataVer}_MSR_80.dta", clear
		disp "USING DIDMSR_2_4_5_6 for MEAUSRE `d'"
		local meas = "mortIH"
		rename flag_died_in_hosp `meas'
		replace `meas' = 0 if missing(`meas')  //78350
		keep if flag_denom_30_all=="D"
	}
	else if inlist(`d', 2){
		use "${baseData}/DID_${dataVer}_MSR_80.dta", clear
		disp "USING DIDMSR_2_4_5_6 for MEAUSRE `d'"
		local meas = "mort"
		rename analysis_variable_all `meas'
		keep if flag_denom_30_all=="D"
	}
	else if inlist(`d', 85){
		use "${baseData}/DID_${dataVer}_MSR_85.dta", clear
		disp "USING DIDMSR_85 for MEAUSRE `d'"
		local meas = "mortPSD"
		rename analysis_variable_all `meas'
		keep if flag_denom_30_all=="D"
	}
	else if inlist(`d', 81,82,83){
		use "${baseData}/DID_${dataVer}_MSR_80_COND_SPCFC.dta", clear
		disp "USING DIDMSR_2_6_COND_SPCFC for MEAUSRE `d'"
		if `d' == 81{ 
			local meas = "mortIHami30"
			rename analysis_variable_ami `meas'
			keep if flag_denom_30_ami=="D"
		}
		else if `d' == 82{ 
			local meas = "mortIHpn30"
			rename analysis_variable_pne `meas'
			keep if flag_denom_30_pne=="D"
		}
		else if `d' == 83{ 
			local meas = "mortIHhf30"
			rename analysis_variable_hf `meas'
			keep if flag_denom_30_hf=="D"
		} 
	}
	else if inlist(`d', 86,87,88){
		use "${baseData}/DID_${dataVer}_MSR_85_COND_SPCFC.dta", clear
		disp "USING DIDMSR_85_COND_SPCFC for MEAUSRE `d'"
		if `d' == 86{ 
			local meas = "mortPSDami30"
			rename analysis_variable_ami `meas'
			keep if flag_denom_30_ami=="D"
		}
		else if `d' == 87{ 
			local meas = "mortPSDpn30"
			rename analysis_variable_pne `meas'
			keep if flag_denom_30_pne=="D"
		}
		else if `d' == 88{ 
			local meas = "mortPSDhf30"
			rename analysis_variable_hf `meas'
			keep if flag_denom_30_hf=="D"
		} 
	}
	else if inlist(`d', 7,9,10,11) {
		use "${baseData}/DID_${dataVer}_MSR_7_9_10_11.dta", clear
		disp "USING DID_7_9_10_11 for MEAUSRE `d'"
		if `d' == 7{ 
			local meas = "readmit30"
			rename analysis_variable_all `meas'
			keep if flag_denom_30_all=="D"
		}
		else if `d' == 9{ 
			local meas = "readmitami30"
			rename analysis_variable_ami `meas'
			keep if flag_denom_30_ami=="D"
		}
		else if `d' == 10{ 
			local meas = "readmitpn30"
			rename analysis_variable_pne `meas'
			keep if flag_denom_30_pne=="D"
		}
		else if `d' == 11{ 
			local meas = "readmithf30"
			rename analysis_variable_hf `meas'
			keep if flag_denom_30_hf=="D"
		}
	}
	else if inlist(`d', 18,20,21,22) {
		use "${baseData}/DID_${dataVer}_MSR`d'_SPLIT.dta", clear
		disp "USING DID`d' for MEAUSRE `d'"
			if `d' == 18{ 
			local meas = "mpaypost30"
			rename analysis_variable_all `meas'
			rename analysis_variable_inp `meas'_inp
			rename analysis_variable_car `meas'_car
			rename analysis_variable_out `meas'_out
			rename analysis_variable_snf `meas'_snf	
			rename analysis_variable_hha `meas'_hha
			rename analysis_variable_hsp `meas'_hsp
			rename analysis_variable_dme `meas'_dme
			/*
				*for average 30 PD payment
			rename analysis_avg_all `meas'_avg
			rename analysis_avg_inp `meas'_avg_inp
			rename analysis_avg_car `meas'_avg_car
			rename analysis_avg_out `meas'_avg_out
			rename analysis_avg_snf `meas'_avg_snf	
			rename analysis_avg_hha `meas'_avg_hha
			rename analysis_avg_hsp `meas'_avg_hsp
			rename analysis_avg_dme `meas'_avg_dme
			
			
			*for number of 30 PD payments
			rename n_all `meas'_n
			rename n_inp `meas'_n_inp
			rename n_car `meas'_n_car
			rename n_out `meas'_n_out
			rename n_snf `meas'_n_snf	
			rename n_hha `meas'_n_hha
			rename n_hsp `meas'_n_hsp
			rename n_dme `meas'_n_dme
			*/
			keep if flag_denom_30_all=="D"
		}
		else if `d' == 20{ 
			local meas = "mpaypost60"
			rename analysis_variable_all `meas'
			rename analysis_variable_inp `meas'_inp
			rename analysis_variable_car `meas'_car
			rename analysis_variable_out `meas'_out
			rename analysis_variable_snf `meas'_snf	
			rename analysis_variable_hha `meas'_hha
			rename analysis_variable_hsp `meas'_hsp
			rename analysis_variable_dme `meas'_dme			
			keep if flag_denom_60_all=="D"
		}
		else if `d' == 21{ 
			local meas = "mpaynoninp"
			rename analysis_variable_all `meas'
			rename analysis_variable_car `meas'_car
			rename analysis_variable_out `meas'_out
			rename analysis_variable_dme `meas'_dme
			keep if flag_denom_all_all=="D"	
		}
		else if `d' == 22{ 	
			local meas = "mpayinp"
			rename analysis_variable_all `meas'
			rename analysis_variable_car `meas'_car
			rename analysis_variable_out `meas'_out
			rename analysis_variable_dme `meas'_dme
			rename analysis_variable_nhp `meas'_nhp
			gen `meas'_hp = `meas' - `meas'_nhp
			keep if flag_denom_all_all=="D"
		}
	}
	else{
		use "${baseData}/DID_${dataVer}_MSR`d'.dta", clear
		disp "USING DID`d' for MEAUSRE `d'"
		if `d' == 3{ 
			local meas = "mort60"
			rename analysis_variable_all `meas'
			keep if flag_denom_60_all=="D"
		}	
		else if `d' == 8{ 
			local meas = "readmit60" 
			rename analysis_variable_all `meas'
			keep if flag_denom_60_all=="D"
		}
		else if `d' == 12{ 
			local meas = "obs24prior"
			rename analysis_variable_all `meas'
			keep if flag_denom_all_all=="D"
		}
		else if `d' == 13{ 
			local meas = "obs24post"
			rename analysis_variable_all `meas'
			keep if flag_denom_all_all=="D"
		}
		else if `d' == 14{ 
			local meas = "icu"
			rename analysis_variable_all `meas'
			keep if flag_denom_all_all=="D"
		} 
		else if `d' == 15{ 
			local meas = "los" 
			rename analysis_variable_all `meas'
			keep if flag_denom_all_all=="D"
		}
		else if `d' == 16{ 
			local meas = "ed30" 
			rename analysis_variable_all `meas'
			keep if flag_denom_all_all=="D"
		}
		else if `d' == 17{ 
			local meas = "ed60" 
			rename analysis_variable_all `meas'
			keep if flag_denom_all_all=="D"
		}
		else if `d' == 19{ 
			local meas = "mpaypac30" 
			rename analysis_variable_all `meas'
			keep if flag_denom_30_all=="D"
		}
		else if `d' == 99{ 
			local meas = "pacuse" 
			rename analysis_variable_all `meas'
			keep if flag_denom_30_all=="D"
		}
	}
	
	

*** set binary flag	
	local bFlag 0
	if inlist(`d', 2, 80,81,82,83,85,86,87,88,3,7,8,9,10,11,12,13,14,16,17,99){
		local bFlag 1
	}
}	

*** set inpatient vs post-discharge flag
	local pdFlag 5
	if inlist(`d', 2, 80,81,82,83,85,86,87,88,3,7,8,9,10,11,18,20,12,13,16,17,19,99){
		local pdFlag 6
	}
	disp "CURRENT MEAUSRE NUMBER IS # `d' NAMED `meas' AND HAS BINARY FLAG `bFlag'"
	
qui{
	*for factor var use
	capture tabulate prvdr_num, gen(hospital)
	capture drop hpid
	capture destring prvdr_num, gen(hpid)

	*fix HBPCI
	capture replace HBPCI = 0 if HBPCI ==99
	capture gen treat_post = HBPCI*post
	tab treat_post
	tab HBPCI post
	
	*disp "DROP PROBLEMATIC COMPARISON PROVIDER"
	drop if inlist(prvdr_num,"360113")
	
	tab drg_weight
	*Drop claims that have a MS DRG weight greater than 30
	drop if drg_weight>30
	
	*generate aggregate time periods
	gen baseline = 0
	replace baseline = 1 if !inlist(quarter, "2013-2","2013-3", "2013-4", "2014-1","2014-2", "2014-3", "2014-4","2015-1") & !inlist(prvdr_num,"170183","340049","050708","520196","050697")
	replace baseline = 1 if !inlist(quarter, "2014-1","2014-2", "2014-3", "2014-4", "2015-1") & inlist(prvdr_num,"170183","340049","050708","520196","050697")
	
	gen sincebpci = 0
	replace sincebpci = 1 if inlist(quarter, "2013-2","2013-3", "2013-4", "2014-1","2014-2", "2014-3", "2014-4","2015-1") & !inlist(prvdr_num,"170183","340049","050708","520196","050697")
	replace sincebpci = 1 if inlist(quarter, "2014-1","2014-2", "2014-3", "2014-4","2015-1") & inlist(prvdr_num,"170183","340049","050708","520196","050697")	
	
	gen year1 = 0
	replace year1 = 1 if inlist(quarter, "2013-2","2013-3", "2013-4", "2014-1") & !inlist(prvdr_num,"170183","340049","050708","520196","050697")
	replace year1 = 1 if inlist(quarter, "2014-1") & inlist(prvdr_num,"170183","340049","050708","520196","050697")
	
	gen lastQtr = 0
	replace lastQtr = 1 if inlist(quarter, "2015-2")
	
	drop if quarter > "2015-2"
}
	

qui{
	if inlist(`d',18 /*,20*/) {
		local vlist `meas' /*`meas'_inp `meas'_car `meas'_out `meas'_snf `meas'_hha `meas'_hsp `meas'_dme	`meas'_avg `meas'_avg_inp `meas'_avg_car `meas'_avg_out `meas'_avg_snf `meas'_avg_hha `meas'_avg_hsp `meas'_avg_dme `meas'_n `meas'_n_inp `meas'_n_car `meas'_n_out `meas'_n_snf `meas'_n_hha `meas'_n_hsp `meas'_n_dme	*/	
	}	
	/*
	else if inlist(`d',21) {
		local vlist `meas' `meas'_car `meas'_out `meas'_dme
	}
	*/
	else if inlist(`d',22) {
		local vlist `meas' `meas'_hp `meas'_car `meas'_out `meas'_dme `meas'_nhp
	}
	else{
		local vlist `meas'
	}
}

*vlist will get submeasures as well

levelsof quarter, local(qtlist)
levelsof prvdr_num, local(allType)
capture tabulate quarter, gen(qtr)

local allPeriods baseline sincebpci year1 lastQtr qtr1 qtr2 qtr3 qtr4 qtr5 qtr6 qtr7 qtr8 qtr9 qtr10 qtr11 qtr12 qtr13 qtr14 qtr15 qtr16 qtr17 qtr18 
local allGroups "all actives exits expansive targeted phc 170183	310005	310006	310010	310012	310014	310015	310019	310024	310031	310032	310038	310044	310050	310051	310069	310070	310073	310081	310092	310096	310108	310110	310111"
//"all actives exits expansive targeted phc" // 100077	310006	230227	310070	310015	210022	310108	310047	110010	450462	070033	310110	360074	040055	310019	330332	310014	310012	310003	310001	490007	310044	500001	140114	410007	310073	310031	070002	310096	310009	310038	450424	310051	140252	490057	070028	310092	310024	230151	070034	250141	030103	310111	140082	010139	100008	330245	310050	440161	100217	330106	520027	310010	440125	230024	340032	050708	110076	310008	330046	100254	310005	100068	070016	450083	310081	330160	330198	490011	220075	050125	100173	070020	140065	490093	180130	310069	310076	310032	260105	360155	070025	490017	340049	450324	230002	490046	390102	100264	280030	490119	340073	050724	450702	190065	310075	150153	390116	100223	360076	170183	520013	050697	190263	520196"
local types HCONT HBPCI

disp "`allGroups'"
disp "`allPeriods'"
foreach s of local types{
foreach v of local vlist{
	foreach z of local allGroups{
		foreach q of local allPeriods{
		preserve
				local QC 1
				local QN 1
				local phcSkip 0
				
				keep if `q' == 1 & `s' == 1
							
				if "`z'" == "actives"{
				keep if HBPCIC==1 | HCONTC==1
			}
				else if "`z'" == "exits"{
				keep if HBPCIX==1 | HCONTX==1
			}
				else if "`z'" == "expansive"{
				keep if HBPCIE==1 | HCONTE==1
			}
				else if "`z'" == "targeted"{
				keep if HBPCIT==1 | HCONTT==1
			}
				else if "`z'" == "phc"{
				keep if HBPCIPHC==1 | HCONTPHC==1
				*this prevent PHC analyses from running on condition-specific mortality
				if inlist(`d',81,82,83,86,87,88){
					local phcSkip 1
				}
			}
				else if "`z'" == "all"{
			//all bpci - do nothing
			}
				else{
					*this subsets the data for hospital-level analysis
					keep if (prvdr_num=="`z'" | CONT`z'==1)
					summarize `v'
					*kansas: mortality and icu will not converge, QC will prevent
					*        the hospital level DID from running 
					if (!((r(N)>0 & r(sum)>0))) | ("`z'" == "170183" & (inlist(`d',2,80,81,82,83,85,86,87,88) |`d'==14)){
						local QC 0
					}
				}	

				*QN will cover ALL and ACTIVE COHORTS	and 
				*	drop Kansas and Kansas Controls for mortality and icu
				if inlist(`d',80,81,82,83,85,86,87,88,2, 14) {
					local QN 0
				}

		disp "-==========================================================-"
		disp "**********Quarterly DID: `meas' OR `v' for `z' Cohort************"
		disp "-==========================================================-"
		disp "Pre Post Sample sizes"
			tab HBPCI post
		disp "Quarterly Sample Sizes"
			tab HBPCI qtr

					
*run model & compute fitted y
			if `QC'{
				if !(`QN'){
					tab prvdr_num if prvdr_num == "170183"
					tab prvdr_num if CONT170183 == 1
					drop if ((prvdr_num == "170183" | CONT170183==1))
				}
				//if !(`phcSkip'){
					runModel `v' `bFlag'
					
					local sigVal = 99
				if substr("`q'",1,3)=="qtr"{
					local bN    = `r(N)'
					local bRate = `r(mean)'
					local bStd  = `r(se)'*sqrt(`r(N)')
					post `mypost' ("`z'") ("`q'") ("`s'") ("`v'") (`r(mean)') (`r(se)') (`r(lb)') (`r(ub)') (`r(N)') (`sigVal')
				}
				else if ("`q'" == "baseline"  ){
					local bN    = `r(N)'
					local bRate = `r(mean)'
					local bStd  = `r(se)'*sqrt(`r(N)')
					post `mypost' ("`z'") ("`q'") ("`s'") ("`v'") (`r(mean)') (`r(se)') (`r(lb)') (`r(ub)') (`r(N)') (`sigVal')
				}
				else{
					local std = `r(se)'*sqrt(`r(N)')
					disp "`bN' , `bRate' , `bStd' , `r(N)' , `r(mean)' , `std'"
					local cN =`r(N)'
					local cRate = `r(mean)'
					local cSe   = `r(se)'
					local cLb    = `r(lb)'
					local cUb    = `r(ub)'
					ttesti `bN' `bRate' `bStd' `cN' `cRate' `std', unequal
					local sigVal = `r(p)'				
					post `mypost' ("`z'") ("`q'") ("`s'") ("`v'") (`cRate') (`cSe') (`cLb') (`cUb') (`cN') (`sigVal')
				}
				
				//} //END of PHCSKIP		
			} //END of QC

		restore
		} //END of Cohort loop	
	} //END of qloop
	} //end of vloop
} //end of s loop
	}	//END of Measure loop

log close
postclose `mypost'
