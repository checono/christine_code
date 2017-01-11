/*
	Created by:DR 
	Last Updated: 15.11.17
	Objective : CCTP PSM Beneficiary-Level Matching code for quarter datasets created for PSM
				PSM identification: treatment (served ==1) and potential control group (served ==0)
				General method requirements: no replacement, caliper requirement, NN
				--> Instead of  predicting propensity score based on mid-2015 specifications (a kitchen-sink approach) I reduced the number of covariates 
					within the probit by removing months 2 through 6 expenditure measures and HOSPITAL level variables for this beneficiary matching. 
					The PSM currently employs the following:

					[x] "exact" matching on a beneficiary dual eligibility status, whether they were discharged to a SNF, within HRR, and within index quarter period
						using PSMATCH2.do.  I could stratify and match on subsamples of these variables to enforce exact matching but instead aim for a relatively 
						close approximation of exact matching that simply weights the predicted propensity by these three charateristics (dual, snf discharge, HRR) - NOTE data
						is already separated by program quarter of index discharges. This method allow for sub-cohort analyses (though not neccesarily at the hospital level).
					[x] There are HRRs that have (# of non-CCTP benes > # ofCCTP benes) or (non-CCTP benes = 0).  Because the CMS approved methodology requires noreplacement NN matching(within
						a specific caliper) beneficiaries within these HRRs are matched differently (starting around line 180) by allowing cross-HRR matching AFTER  removing CCTP and non-CCTP
						beneficiaries already matched under the "exact" matching paradigm above.
					[x] matching variables are listed in local macro matchingChar
				
	
	Input     : (CCTP Program) Quarterfiles that contain all beneficiaries from CCTP hospitals and Control/Comparison Eligible beneficiaries
				 Univerisal exclusions applied (at time of creation in SAS) to these files excludes 
					[x] Benes that Died during admission: CC_DENOM_EXCL_EXPIRED
					[x] Benes that had a transfer: FLAG_DENOM_EXCL_LOS_YR
					[x] Benes that had a length of stay > 1 year: CC_DENOM_EXCL_LOS_YR
					[x] Those with discharge from non-acute care hospital: CC_DENOM_EXCL_NON_ACUTE_DSCHRG
					[x] Benes without FFS Coverage in month of discharge: CC_DENOM_EXCL_NO_FFS_AB
				
				 File naming convention: PSM_[YEAR]_[QUARTER]
				  
	Output    : 
				* A singular file of all treatment benes and matched comparison benes 
				* Quarter file match statistics (all potential control benes and matched)
				* All quarter combined matched statistics
	
	Notes     : 
				* Beneficiaries that are actually served by CCTP at CCTP hospitals are identified as 
					program_status=="SERVED" & in_lb  --> served == 1
				* Potential controls are identified as 
					program_status=="CONTROL ELIGIBLE" & missing(served)  --> served == 0
				* CCTP Program quarter starts from Feb 1, 2012

*/



*set data version
global dataVer "2015_10"

*set run number
global runNum 3

*set data path
global baseData    "S:\Shared\CHerlihy\data/${dataVer}"

*set work folder
global interimData "S:\Shared\CHerlihy\data/${dataVer}/initirm"

*set output folder
global outData     "S:\Shared\CHerlihy\data/${dataVer}/output"

*set log folder
global logData     "S:\Shared\CHerlihy\data/${dataVer}/log"

*retrieve all PSM_* files from specified directory
local mFiles : dir "${interimData}" files "PSM_2*"
	*test retrival
		display `mFiles'
	
*contains most recent psmatch2 ado that shows variance ratios		
adopath + "S:\Shared\CHerlihy\ado"


*initiate log
capture log close
log using "${logData}/PSM_runs_withinHRR_${runNum}", replace


*matching variables
*local matchingChar  hhrnum snf_disch dual_qtr age male black hisp oth_dk charlindex admissions readmissions los ed_visits* admissions_zero readmissions_zero los_zero pay*pre1_zero pay*pre26_zero imp_hcc_4cctp cc* ami hf pnu copd bdtot admtot vem voth for_profit percent_medicare percent_medicaid cmi  cbsa_division cbsa_metro 
*local matchingChar   age male black hisp oth_dk charlindex admissions readmissions los ed_visits* admissions_zero readmissions_zero los_zero pay*pre1_zero pay*pre26_zero imp_hcc_4cctp cc* ami hf pnu copd bdtot admtot vem voth for_profit percent_medicare percent_medicaid cmi  cbsa_division cbsa_metro 

local matchingChar   dual_qtr snf_disch age male black hisp oth_dk charlindex admissions readmissions los ed_visits_ip ed_visits_op  pay*pre1  imp_hcc_4cctp cc* ami hf pnu copd //bdtot admtot vem voth for_profit percent_medicare percent_medicaid cmi  


cd ${interimData}

*exact matching on HRR, Dual Status, SNF stay, and index discharge quarter 
*-> data is already separated by quarter

foreach v of local mFiles{
	use `v', clear
		
		local qtr = quarter[1]

	*m: prematch quater level assessment of balance
		disp "************************************************"
		disp "-----> PRE-MATCH BALANCE of Quarter `qtr' <-----"
		disp "************************************************"
		pstest `matchingChar', treated(served) raw
	
	* individuals dropped by the statement below will be matched in a different manner because they either have no non_CCTP benes
	* in the HRR or insufficient non-CCTP benes for 1:1 no replacement matches
	drop if hrrFlag ==1
	
	disp "*****************************************************"
	disp "----------> MATCHING FOR QUARTER: `qtr' <------------"
	disp "*****************************************************"
	
	disp "Active HRRs:"
		tab hrrnum served
	/*************/

			
			set seed 195087463
			capture drop randomnumber
			generate randomnumber = runiform()
			
	        sum served `matchingChar'
			tab served 
		
		*m: compute pscore
			capture noisily{
				probit served i.hrrnum `matchingChar'
			}
			
			if _rc !=0{
				disp "************************************************"
				disp "-------------> PROBIT SPEC ERROR  <-------------"
				disp "************************************************"
			} 
			else{
				predict ps if e(sample), pr
		
				*m: set caliper for match
				local caliper = 0.25 * r(sd)
	
				*m: weighting scheme to force importance of dual quarter and snf_discharge
			gen ps2 = hrrnum*1000 + dual_qtr*10+ snf_disch*100 +  ps if e(sample)
				
			drop if missing(ps2)
			sort randomnumber

		*m: NN(1) match w/o replacement, caliper requirement, and common support
			capture noisily psmatch2 served, pscore(ps2) neighbor(1) caliper(`caliper') common noreplacement
			if _rc !=0{
				disp "************************************************"
				disp "--------------> PSMATCH 2 ERROR  <--------------"
				disp "************************************************"
			} 
			else{
			
				*m: retain matches
					sort _id
					 
					clonevar bid_of_match = bene_id
					clonevar cid_of_match = clm_id

					replace bid_of_match = bene_id[_n1]
					replace cid_of_match = clm_id[_n1]

				*m: standardized test stats
					capture noisily pstest  `matchingChar', both
					if _rc !=0{
						disp "************************************************"
						disp "---------------> PS TEST ERROR  <---------------"
						disp "************************************************"
					}

				*m: isolate served and matched counter parts
					keep if !missing(_weight) 
					*keep if served == 1
				
				sort bene_id clm_id
					tab _weight _treated
					tab _support _treated
				save mSet_fuzzy_`qtr'_withinHRR, replace
			}
		} 
} //EO foreach v of local mFiles
	
	
/**************************************************************************************************************************/
/* 
	THIS NEXT PART MATCHES CCTP BENEFICIARIES THAT WERE NOT MATCHED ABOVE (WITHIN HRR) TO NON-CCTP BENEFICIARIES 
	THAT HAVE NOT YET BEEN MATCHED
*/
/**************************************************************************************************************************/
log close 

log using "${logData}/PSM_runs_nonHRR_${runNum}", replace

foreach v of local mFiles{
	use `v', clear
	
	
	local qtr = quarter[1]
	sort bene_id clm_id

	merge 1:1  bene_id clm_id using mSet_fuzzy_`qtr'_withinHRR, keepusing(bene_id clm_id)

	
	tab _merge
	
	*retain all CCTP and non CCTP beneficiaries that have not been matched
	keep if _merge == 1

	disp "*****************************************************"
	disp "----------> MATCHING FOR QUARTER: `qtr' <------------"
	disp "*****************************************************"
	
	disp "Active HRRs:"
		tab hrrnum served
	/*************/

			
			set seed 195087463
			capture drop randomnumber
			generate randomnumber = runiform()
			sort randomnumber
			
	        sum served `matchingChar'
			tab served 
		
		*m: compute pscore
			capture noisily{
				probit served `matchingChar'
			}
		
			if _rc !=0{
				disp "************************************************"
				disp "-------------> PROBIT SPEC ERROR  <-------------"
				disp "************************************************"
			} 
			else{
				predict ps if e(sample), pr
		
				*m: set caliper for match
					local caliper = 0.25 * r(sd)
	
				*m: weighting scheme to force importance of dual quarter and snf_discharge
					gen ps2 = dual_qtr*10+ snf_disch*100 +  ps if e(sample)
				
				drop if missing(ps2)
				sort randomnumber

			*m: NN(1) match w/o replacement, caliper requirement, and common support
			capture noisily psmatch2 served, pscore(ps2) neighbor(1) caliper(`caliper') common noreplacement
			if _rc !=0{
				disp "************************************************"
				disp "--------------> PSMATCH 2 ERROR  <--------------"
				disp "************************************************"
			} 
			else{
			
				*m: retain matches
					sort _id
					 
					clonevar bid_of_match = bene_id
					clonevar cid_of_match = clm_id

					replace bid_of_match = bene_id[_n1]
					replace cid_of_match = clm_id[_n1]

				*m: standardized test stats
					capture noisily pstest  `matchingChar', both
					if _rc !=0{
						disp "************************************************"
						disp "---------------> PS TEST ERROR  <---------------"
						disp "************************************************"
					}

				*m: isolate served and matched counter parts
					keep if !missing(_weight) 
					*keep if served == 1
				
				sort bene_id clm_id
					tab _weight _treated
					tab _support _treated
	
				save mSet_fuzzy_`qtr'_nonHRR, replace
			}
		}
} //EO foreach v of local mFiles	

log close


*collect matched samples of beneficiaries 
clear
 local mFiles : dir "${interimData}" files "mSet_fuzzy_*"
 disp `mFiles'

*capture within HRR matches
 foreach v of local mFiles{
	append using `v'
 }

tab _weight _treated
tab _support _treated

tab quarter served if _weight==1
capture log close
log using "${logData}/PSM_runs_POST_MATCH _BALANCE_${runNum}", replace
pstest `matchingChar', treated(served) raw

levelsof quarter, local(qts)

foreach q of local qts{
	disp "************************"
	disp "Balance for Quarter: `q'"
	disp "************************"
	preserve
		keep if quarter == "`q'"
		tab served
		pstest `matchingChar', treated(served) raw
	restore
}

log close 

capture drop _merge
save ${outData}/mSetFull,replace	
drop if _weight!=1
	tab quarter served

keep bene_id clm_id clm_thru_dt served quarter
sort bene_id clm_id 
save ${outData}/mSet_fuzzy_index,replace		



/*********************************/
/*merge with QDM6 measure dataset*/
/*********************************/
use ${outData}/mSet_fuzzy_index,clear		

tab served
merge 1:1 bene_id clm_id clm_thru_dt using "S:\Shared\CHerlihy\data\2015_10\measures_60_2015_10_cmp.dta"
tab _merge
keep if _merge == 3
duplicates drop
capture drop _merge
save S:\Shared\CHerlihy\data\2015_10\servedBeneAnalyticFile.dta,replace




