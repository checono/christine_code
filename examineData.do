/*******************************************************************************
Purpose: Examine BPCI Strategic Behavior data pull dta files.
		Check to ensure all required covariates are present in this dataset
		Run logit/probit on a 10% sample of the file
		
Author: Christine Herlihy

Last Updated: 2/24/2016
*******************************************************************************/
ssc inst distinct //doesn't work in CCW??

*******************************************************************************/
*Get a 10% sample from master data set

*_BASE_2016_01_STRBHV_DENOMINATOR
use "S:\Shared\AShangraw\data\2016_01\_base_2016_01_strbhv_denominator.dta", clear
preserve
sample 10
save "S:\Shared\AShangraw\data\2016_01\_base_2016_01_strbhv_denominator_SAMPLE.dta", replace
restore

*******************************************************************************/

*Use the 10% sample for analysis: 
use "S:\Shared\AShangraw\data\2016_01\_base_2016_01_strbhv_denominator_SAMPLE.dta", clear

*Tab by provider number and BPCI (logic check to make sure prvdr_cat_bpci == the BPCI dummy)
tab prvdr_num prvdr_cat_bpci

*Generate a variable for whether a single NPI is the attending or (?) operating phys @ multiple hospitals
by at_physn_npi prvdr_num, sort: gen at_mulPriv = _n == 1
by at_physn_npi: replace at_mulPriv = sum(at_mulPriv)
by at_physn_npi: replace at_mulPriv = at_mulPriv[_N]

tab at_mulPriv 

by op_physn_npi prvdr_num, sort: gen op_mulPriv = _n == 1
by op_physn_npi: replace op_mulPriv = sum(op_mulPriv)
by op_physn_npi: replace op_mulPriv = op_mulPriv[_N]
tab op_mulPriv 

//Covariates from previous BPCI reports (need to figure out which ones we have / which ones we need to run the compression code in order to generate) 
global icd9vars "twh_anyhemo twh_anyvent twh_tpntransf twh_clinemngt twh_sevprsrulcer"
global cc_flgs "d_alzh_comb d_ami d_asthma d_atrial_fib d_cancer d_chf d_copd d_diabetes d_hip_fracture d_hypoth d_depression d_stroke_tia d_anemia d_cataract d_chronickidney d_glaucoma d_hyperl d_hyperp d_hypert d_ischemicheart d_osteoporosis d_ra_oa"
global demo2 "age65_74 age75_84 age85up gender raceBlack raceHisp raceOther hcc_score hccmiss ln_drg dual"

global covariates $demo2 $cc_flgs $icd9vars
sum CLM_SRC_IP_ADMSN_CD //categorical;  see codebook for decision rules
sum PTNT_DSCHRG_STUS_CD  //categorical; see codebook for decision rules
regress Y i.post treat_post i.pvdr i.qtr $covariates , vce(cluster hosp_qrt)
