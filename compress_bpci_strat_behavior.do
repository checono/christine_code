global date "160311"
capture log close
log using "S:\Shared\CHerlihy\bpci_strat_behavior\compressed\compress_${date}_add.log", replace 
********************************************************************************
***March 9, 2016
***Adapted by: Christine Herlihy

/* 
   This script will read in all files from specified directory and compress them
   into smaller files by changing variable type into the smallest precision 
   needed to store the data. Such as Long to Short, fewer characters, etc.
   
   Original do file that this script is modeled after:
   S:\Shared\AShangraw\data\2016_01\compressDiD_2016_01_160123.do
   
*/

********************************************************************************
global inputData "S:\Shared\AShangraw\data\2016_01\_base_2016_01_strbhv_denominator.dta"
global didDir "S:\Shared\CHerlihy\bpci_strat_behavior\compressed"

set more off


use "S:\Shared\AShangraw\data\2016_01\_base_2016_01_strbhv_denominator.dta", clear
	/*adjustments to compressed folder */
		//keep if flag_denom_30_all=="D"

		gen age = bene_age_at_end_ref_yr
		gen age0_18 = age<=18 & age!=.
		gen age19_64 = age>=19 & age<=64 & age!=.
		gen age65_74 = age>=65 & age<=74 & age!=.
		gen age75_84 = age>=75 & age<=84 & age!=.
		gen age85up = age>=85 & age!=.

		gen age0_64= (age0_18==1|age19_64==1) & age!=. //DZ

		foreach x in age0_64 age65_74 age75_84 age85up {
			replace `x'=. if age==.
		}
	
		rename bene_race_cd race
		replace race="9" if inlist(race,"0","3","4","6")
		gen race2=0
		gen race5=0
		gen race9=0

		replace race2=1 if race=="2"
		replace race5=1 if race=="5"
		replace race9=1 if race=="9"

		rename race2 raceBlack
		rename race5 raceHisp
		rename race9 raceOther
		gen raceWhite = race=="1"
	
		***************************************************
		* Create Indicator Variables From OREC 
		***************************************************
/*
		gen disabled = orec==1
		gen esrd = orec==2
		gen dis_esrd = orec==3
		global orec disabled esrd dis_esrd
*/		
		***universal changes	
		rename reporting_yr_qtr_from_dt quarter
		rename dual_eligibility_mo_admission dual
	
		gen hccmiss=0
		replace hccmiss=1 if hcc_score==. 
		replace hcc_score=1 if hcc_score==. 
	

		*for se clustering
		gen hosp_qrt=prvdr_num+"_"+quarter

	*******************************		
	***	call BPCI groupings do file
	*******************************
		do "S:\Shared\AShangraw\data\2015_07\BPCIgrouping_150708.do"	

**
*Adding other risk adjusters	
**


gen cancer = (cancer_breast==1 | cancer_colorectal==1 | cancer_prostate==1 | cancer_lung==1 | cancer_endometrial==1)

foreach z of varlist ami alzh alzh_demen atrial_fib cataract chronickidney copd chf diabetes glaucoma hip_fracture ischemicheart ///
                     depression osteoporosis ra_oa stroke_tia cancer_breast cancer_colorectal cancer_prostate cancer_lung        ///
					 cancer_endometrial anemia asthma hyperl hyperp hypert hypoth {

						gen d_`z'= (`z'==1 | `z'==3)
}

gen d_cancer = (d_cancer_breast==1 | d_cancer_colorectal==1 | d_cancer_prostate==1 | d_cancer_lung==1 | d_cancer_endometrial==1)
gen d_alzh_comb= (d_alzh==1 | d_alzh_demen)


//DZ adds groupings of chronic conditions per discussions with W Muyiwa

/*
NO LONGER USE DRG DUMMIES
*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
merge m:1 clm_drg_cd using UpdatedMSDRGGroups_20150325_xWalk, keepusing(clm_drg_group)	
*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm

drop _merge

tab clm_drg_group, gen(new_drg_)	
*/	  
*ICD-9 variables

	forvalues n = 1/25 {
	* Check ICD9 Variables and generate error-free versions in dot format
	*Diagnosis codes
	icd9 check icd_dgns_cd`n', generate(icd_dgns_cd`n'_check) 
	generate icd_dgns_cd`n'_clean = icd_dgns_cd`n' if icd_dgns_cd`n'_check == 0
	icd9 clean icd_dgns_cd`n'_clean, dots
	
	*Procedure codes
	icd9p check icd_prcdr_cd`n', generate(icd_prcdr_cd`n'_check) 
	generate icd_prcdr_cd`n'_clean = icd_prcdr_cd`n' if icd_prcdr_cd`n'_check == 0
	icd9p clean icd_prcdr_cd`n'_clean, dots
		 
	* Generate indicator variables for each of the 25 PRCDRS codes
	icd9p generate twh_anyhemo_`n' 	 	= icd_prcdr_cd`n'_clean, range(39.95)
	icd9p generate twh_anyvent_`n'		= icd_prcdr_cd`n'_clean, range(96.70 96.7  96.71 96.72 93.99)
	icd9p generate twh_tpntransf_`n' 	= icd_prcdr_cd`n'_clean, range(99.15)
	icd9p generate twh_clinemngt_`n' 	= icd_prcdr_cd`n'_clean, range(39.91 88.55 38.95 38.93 34.04 35.82 36.10)
	* Generate indicator variables for each of the 25 DGNS codes
	icd9 generate twh_sevprsrulcer_`n' 	= icd_dgns_cd`n'_clean, range(707.0  707.20 707.21 707.22 707.23 707.24 707.25)	
}

	global twh anyhemo anyvent tpntransf clinemngt sevprsrulcer

	foreach var of global twh {
		egen twh_`var' = rowmax(twh_`var'_*)
		tab twh_`var'
	}
	
	
	global twh anyhemo anyvent tpntransf clinemngt sevprsrulcer
	foreach var of global twh {
		gen twh_`var'_mi = 0
		replace twh_`var'_mi = 1 if twh_`var' == .
		replace twh_`var' = 0 if twh_`var' ==.
		tab twh_`var'
		tab twh_`var'_mi
	}

	foreach p of var prir_yr_total_medicare_pmt prir_yr_acute_stays prir_yr_snf_gt_30days{
		replace `p' = 0 if `p'==.
	}
		
*remove old baseline
	drop if inlist(quarter, "2010-1", "2010-2","2010-3", "2010-4") 

	*for factor var use
	egen qtr = group(quarter)
	*egen pvdr = group(prvdr_num)

*setup Treatment interactions	
	gen     post = 0
	replace post = 1 if qtr > 9 & !inlist(prvdr_num,"170183","340049","050708","520196","050697")
	replace post = 1 if qtr > 12 & inlist(prvdr_num,"170183","340049","050708","520196","050697")
	
	*fix HBPCI
	replace HBPCI = 0 if HBPCI ==99
	gen treat_post = HBPCI*post
	tab treat_post
	
			*capture tabulate prvdr_num, gen(hospital)
		capture destring prvdr_num, gen(hpid)
	
		capture gen years = substr(quarter,1,4)
		capture tabulate yrs, gen(years)

	
		*disp "DROP PROBLEMATIC COMPARISON PROVIDER"
		drop if inlist(prvdr_num,"360113")
		tab drg_weight
		*drop if drg_weight > 30
		gen lndrg_weight = ln(drg_weight)
	    gen lnaltdrg_weight = ln(alt_drg_weight)

*drop unused
	capture drop  icd_prcdr_* icd_dgns_* 
	capture drop  prvdr_cat_bpci prvdr_cat_tc nch_drg_outlier_aprvd_pmt_amt clm_drg_outlier_stay_cd clm_pps_cptl_drg_wt_num clm_pps_old_cptl_hld_hrmls_amt clm_pps_cptl_excptn_amt clm_pps_cptl_ime_amt clm_pps_cptl_dsprprtnt_shr_amt clm_pps_cptl_outlier_amt clm_pps_cptl_fsp_amt clm_tot_pps_cptl_amt dual_eligibility_mo_discharge clm_poa_ind_sw* ime_op_clm_val_amt dsh_op_clm_val_amt hypoth_ever hypoth_mid hypoth hypert_ever hypert_mid hypert hyperp_ever hyperp_mid hyperp hyperl_ever hyperl_mid hyperl asthma_ever asthma_mid asthma anemia_ever anemia_mid anemia cancer_endometrial_ever cancer_endometrial_mid cancer_endometrial cancer_lung_ever cancer_lung_mid cancer_lung cancer_prostate_ever cancer_prostate_mid cancer_prostate cancer_colorectal_ever cancer_colorectal_mid cancer_colorectal cancer_breast_ever cancer_breast_mid cancer_breast stroke_tia_ever stroke_tia_mid stroke_tia ra_oa_ever ra_oa_mid ra_oa osteoporosis_ever osteoporosis_mid osteoporosis depression_ever depression_mid depression ischemicheart_ever ischemicheart_mid ischemicheart hip_fracture_ever hip_fracture_mid hip_fracture glaucoma_ever glaucoma_mid glaucoma diabetes_ever diabetes_mid diabetes chf_ever chf_mid chf copd_ever copd_mid copd chronickidney_ever chronickidney_mid chronickidney cataract_ever cataract_mid cataract atrial_fib_ever atrial_fib_mid atrial_fib alzh_demen_ever alzh_demen_mid alzh_demen alzh_ever alzh_mid alzh ami_ever ami_mid ami
compress
save  "${didDir}/marketAnalysis_v2", replace

log close
