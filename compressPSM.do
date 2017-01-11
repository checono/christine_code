/*
	Created by:DR 
	Objective : simple compression code of quarter datasets created for PSM
				that adds the charleston comorbidity index and 
				indentifies the treatment (served ==1) and potential control group (served ==0)
	
	Input     : (CCTP Program) Quarterfiles that contain all beneficiaries from CCTP hospitals and Control/Comparison Eligible beneficiaries
				 Univerisal exclusions applied (at time of creation in SAS) to these files excludes 
					[x] Benes that Died during admission: CC_DENOM_EXCL_EXPIRED
					[x] Benes that had a transfer: FLAG_DENOM_EXCL_LOS_YR
					[x] Benes that had a length of stay > 1 year: CC_DENOM_EXCL_LOS_YR
					[x] Those with discharge from non-acute care hospital: CC_DENOM_EXCL_NON_ACUTE_DSCHRG
					[x] Benes without FFS Coverage in month of discharge: CC_DENOM_EXCL_NO_FFS_AB
				
				 File naming convention: PSM_[YEAR]_[QUARTER]
				  
	Output    : Compressed, ready to match, quarter files that only have index discharges 
				from HRRs that have at least one CCTP beneficiarie found in the list bill.
	
	Notes     : 
				* Beneficiaries that are actually served by CCTP at CCTP hospitals are identified as 
					program_status=="SERVED" & in_lb
				* Potential controls are identified as 
					program_status=="CONTROL ELIGIBLE" & missing(served)
				* CCTP Program quarter starts from Feb 1, 2012

*/

*set data version
global dataVer "2015_10"

*set data path
global baseData    "S:\Shared\CHerlihy\data/${dataVer}"

*set work folder
global interimData "S:\Shared\CHerlihy\data/${dataVer}/initirm"

*set log folder
global logData     "S:\Shared\CHerlihy\data/${dataVer}/log"

*retrieve all PSM_* files from specified directory
local mFiles : dir "${baseData}" files "PSM_2*"
	*test retrival
		display `mFiles'

	
adopath + "S:\Shared\CHerlihy\ado"


*initiate log
capture log close
log using "${logData}/PSM_compression", replace

* set data source directory
cd ${baseData}

tempfile activeHRRS
foreach v of local mFiles{
	use `v', clear
	
		* Calculate Charlson index	
			capture charlson icd_dgns_cd1-icd_dgns_cd25, index(c) assign0
		
		
		* generate quarter identifier from the file name
			gen quarter = substr("`v'",5,6)
		
		* check treatment/control eligibility	
			tab program_status in_lb, mi
		* generate treatment/(potential) comparison group indentifier
			gen served = 1 if program_status=="SERVED" & in_lb
			replace served = 0 if missing(served) & program_status=="CONTROL ELIGIBLE"
		
		* do NOT need to retain benes discharged from CCTP hospitals that were NOT served by CCTP
			drop if missing(served)
			
		* identification test
			tab program_status
			tab in_lb if program_status =="SERVED"
			tab served 
		
			*qui{
				preserve
					capture drop nServed ntServed tServed
	
					gen nServed = abs(served-1)

					* count the number of served and non-served within each HRR
					bys hrrnum: egen ntServed = sum(nServed)
					bys hrrnum: egen tServed = sum(served)
    
					keep hrrnum ntServed tServed 	
					duplicates drop
				/* 
					ensure that there is (1) a positive number of served within and HRR
					and (2) that there are more non-served than served and (3) there is at least 1
					treated beneficiary in any HRR.  This would look like the following condition
					for exact matching that uses PSMATCH2:
						keep if (ntServed > tServed & tServed > 0)
					HOWEVER, given IMPAQ's fuzzy approach - replicated in runPSMv3.do I'll keep this at
						keep if (tServed > 0)
				*/
					keep if (tServed > 0)
					gen hrrFlag = 0
					replace hrrFlag = 1 if (tServed > ntServed) | (ntServed == 0)
					keep hrrnum hrrFlag
					sort hrrnum
			
					tab hrrnum
					save `activeHRRS', replace
				restore

				capture drop _merge

				merge m:1 hrrnum using `activeHRRS'
				keep if _merge ==3
				
				
				drop if missing(hrrnum)
				drop _merge
			
			*}	
		* Remove excess variables
			capture drop ynch* weightch* icd_dgns_cd*
		
		* Recode chronic conditions flags
			foreach p of varlist cc_*{
				recode `p' (1/3=1) (0=0)
			}
		* Compress file
			compress
	
	save ${interimData}/`v', replace
}

