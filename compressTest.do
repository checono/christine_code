use "S:\Shared\CHerlihy\data\2015_12\measures_60_2015_12.dta", clear
	compress
	sort bene_id clm_id clm_thru_dt
	save "S:\Shared\CHerlihy\data\2015_12\measures_60_2015_12_cmp.dta", replace

use "S:\Shared\AShangraw\data\QDM6_X1\_measure_pdschrgepay_30_qdm6_x1.dta",clear
	compress
		sort bene_id clm_id 

		save "S:\Shared\AShangraw\data\QDM6_X1\_measure_pdschrgepay_30_qdm6_x1_cmp.dta",replace

		
		


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

	
		
/*********************************/
/*merge with QDM6 measure dataset*/
/*********************************/
use ${outData}/mSet_fuzzy_index,clear		
disp _N
tab served
merge 1:1 bene_id clm_id  using "S:\Shared\CHerlihy\data\2015_12\measures_60_2015_12_cmp.dta"
tab _merge


keep if _merge == 3
disp _N
duplicates drop
capture drop _merge
save S:\Shared\CHerlihy\data\2015_10\servedBeneAnalyticFile_TEST_1.dta,replace


/*********************************/
use ${outData}/mSet_fuzzy_index,clear		
disp _N
tab served
merge 1:1 bene_id clm_id  using "S:\Shared\AShangraw\data\QDM6_X1\_measure_pdschrgepay_30_qdm6_x1_cmp.dta"
tab _merge


keep if _merge == 3
disp _N
duplicates drop
capture drop _merge
save S:\Shared\CHerlihy\data\2015_10\servedBeneAnalyticFile_TEST_2.dta,replace

