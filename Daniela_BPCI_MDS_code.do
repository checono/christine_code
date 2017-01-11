*************************************************************************
* Christine: running Daniela's code 
* Evaluation of BPCI Model 1
*PAC analysis
*Do file that creates measures using the MDS data file. 
* Measures in this do file were created following the technical specifications 
* saved in IMPAQ's R drive
*************************************************************************

clear all
set more off
cap log close
set logtype text
global Path "S:\Shared\CHerlihy"
cd ${Path}
*Ado directory
*sysdir set PERSONAL dza710:\ado\
*or
adopath + "S:\Shared\alberto\ado"

log using "${Path}\logs\PAC_analysis_090815.txt", replace


*Run this part only once
********************************************************************************
*Aseess MDS_11 MDS_12 MDS_13 and MDS_14 Data files
******************************************************************************** 

foreach x in 11 12 13 14 {

	use S:\Shared\Daniela\bpci\mds\mds_asmt3`x'_r4396, clear
	desc
	
	*Keeping PAIN, Mobility, Number of Falls, and self care measures described in PAC

	keep bene_id trgt_dt a0310b_pps_cd j0400_pain_freq_cd j0500a_pain_efct_sleep_cd /// 
	j0500b_pain_efct_actvty_cd j0600a_pain_intnsty_num j0600b_vrbl_dscrptr_scale_num ///
	g0110e1_locomtn_on_self_cd g0110e2_locomtn_on_sprt_cd g0110f1_locomtn_off_self_cd g0110f2_locomtn_off_sprt_cd ///
	j1700a_fall_30_day_cd j1700c_frctr_six_mo_cd j1700a_fall_30_day_cd j1700b_fall_31_180_day_cd j1700c_frctr_six_mo_cd ///
	g0110g1_dress_self_cd g0110g2_dress_sprt_cd g0110j1_prsnl_hygne_self_cd g0110j2_prsnl_hygne_sprt_cd ///
	g0120a_bathg_self_cd g0120b_bathg_sprt_cd g0110i1_toiltg_self_cd g0110i2_toiltg_sprt_cd g0110h1_eatg_self_cd ///
	g0110h2_eatg_sprt_cd 

	gen mds_year=2000+`x'
	count
	
	codebook bene_id
	
	
	*Assessment code variable a0310b_pps_cd - number of assessment
	tab a0310b_pps_cd
	* keep only 5-day assessments
	keep if a0310b_pps_cd=="01"    
	
	compress
	destring, replace
	save data\pac_sel_data_20`x', replace
}
	

********************************************************************************
*Appending datasets
******************************************************************************** 

use data\pac_sel_data_2011, clear
append using data\pac_sel_data_2012
append using data\pac_sel_data_2013
append using data\pac_sel_data_2014

*ssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss
save Data\pac_sel_2011_2014.dta, replace
*sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss


***********************************************************
* Organize pain, mobility, number of falls and self-care variables
***********************************************************
use Data\pac_sel_2011_2014.dta, clear

destring, replace

*Dropping duplicate records
duplicates report
duplicates drop

* PAC Moderate to Severe Pain
*create new pain variable that combines J0400 and J0600A/B
desc j0400* j0600*

tab1 j0400*, m
rename j0400* j0400
destring j0400, replace force
tab1 j0400, m
replace j0400=. if  j0400==9

rename j0600a_pain_intnsty_num   j0600a
tab1 j0600a, m
destring j0600a, replace force
tab j0600a, m
*replace the unable to determine as missing (so will not included in descr stats and reg)
replace j0600a=. if  j0600a==99
tab j0600a, m

rename j0600b_vrbl_dscrptr_scale_num j0600b
tab1  j0600b, m
destring j0600b, replace force
tab j0600b, m
*replace the unable to determine as missing (so will not included in descr stats and reg)
replace j0600b=. if  j0600b==9
tab j0600b, m


* (1) identify residents who report almost constant/frequent pain (i.e. j0400<=2 ) AND moderate to severe pain (j0600a>5  OR j0600b==2/3)
gen s=(j0400<=2 & ((j0600a>5 & j0600a<.) | (j0600b==2 | j0600b==3)))
replace s=. if (j0400==. | (j0600a==. & j0600b==.))
tab s, m

* (2) identify residents reporting very severe/horrible pain of any frequency (j0600a = 10 OR j0600b=4)
gen q=(j0600a==10 | j0600b==4)
replace q=. if (j0600a==. & j0600b==.)
tab q, m

* pain according to NQF satisfy one of the two above
gen painNQF=(s==1 | q==1)
replace painNQF=. if (s==. | q==.)
tab painNQF, m 
tab s q if painNQF==0, m
drop s q
label var painNQF "pain re-coded according to NQF"


***** Variable "j0500a_pain_efct_sleep_cd" is resident's pain difficulty sleeping b/c of pain over the past 5 days 

desc j0500a_pain_efct_sleep_cd 
tab1 j0500a_pain_efct_sleep_cd , m
* 54 % missing
/*  according to codebook :
    values "-"  is "not assessed or no information", 
	values = "9"  means "unable to determine"
	blank - is not specified in codebook
*/
* for descriptive purposes I collapse all these categories as missing 
destring j0500a_pain_efct_sleep_cd , replace force
label define j0500a_pain_efct_sleep_cd  1"yes" 0"no"  
label values j0500a_pain_efct_sleep_cd   j0500a_pain_efct_sleep_cd  
* replace the unable to determine as missing (so will not included in descr stats and reg)
replace j0500a_pain_efct_sleep_cd=. if  j0500a_pain_efct_sleep_cd==9
tab j0500a_pain_efct_sleep_cd , m
rename j0500a_pain_efct_sleep_cd j0500a
rename j0500a pain_sleep

*** Variables for mobility (keep only locomotion on unit (self/resident assessed-g0110e1)

* g0110e1_locomtn_on_self_cd: locomotion on self
desc g0110e1_locomtn_on_self_cd
tab g0110e1_locomtn_on_self_cd, m
destring g0110e1_locomtn_on_self_cd, replace force

label define  g0110e1_locomtn_on_self_cd  0"independent"  1"supervision"  2"limited assistance"  3"extensive assistance"  4"total dependence"  7"activity occurred once/twice" ///
8"activity did not occurr" 
label values g0110e1_locomtn_on_self_cd g0110e1_locomtn_on_self_cd
tab1 g0110e1_locomtn_on_self_cd, m


* replace records for which activity did not occurr or occurred only once/twice as missing (so will not included in descr stats and reg)
replace g0110e1_locomtn_on_self_cd=.  if g0110e1_locomtn_on_self_cd>=7

gen g0110e1v2=.
replace g0110e1v2=1 if g0110e1_locomtn_on_self_cd>=3 & g0110e1_locomtn_on_self_cd<.
replace g0110e1v2=0 if g0110e1_locomtn_on_self_cd<3
tab g0110e1v2 g0110e1_locomtn_on_self_cd, m
label var g0110e1v2 " G0110E1 ADL Assistance: Locomotion On Self Performance Code/ recode 2"
label define g0110e1v2 0"independent/supervision/limited assistance"  1"extensive ass/total dependence"
label values g0110e1v2 g0110e1v2
rename g0110e1v2 mob_assist 

*** Variables for number of falls in the last 30 days
codebook j1700a_fall_30_day_cd 
destring j1700a_fall_30_day_cd , replace force
* value 9: unable to determine to missing
gen falls_30days=1 if j1700a_fall_30_day_cd==1
replace falls_30days=0 if j1700a_fall_30_day_cd==0
capture label define yesno 1 "yes" 0 "no"
label values falls_30days yesno

tab falls_30days j1700a_fall_30_day_cd

***Self-care variables
codebook g0110g1_dress_self_cd g0110g2_dress_sprt_cd g0110j1_prsnl_hygne_self_cd g0110j2_prsnl_hygne_sprt_cd ///
g0120a_bathg_self_cd g0120b_bathg_sprt_cd g0110i1_toiltg_self_cd g0110i2_toiltg_sprt_cd g0110h1_eatg_self_cd ///
g0110h2_eatg_sprt_cd

destring g0110g1_dress_self_cd g0110g2_dress_sprt_cd g0110j1_prsnl_hygne_self_cd g0110j2_prsnl_hygne_sprt_cd ///
g0120a_bathg_self_cd g0120b_bathg_sprt_cd g0110i1_toiltg_self_cd g0110i2_toiltg_sprt_cd g0110h1_eatg_self_cd ///
g0110h2_eatg_sprt_cd, force replace


*Selected variables:
codebook g0110g1_dress_self_cd g0110j1_prsnl_hygne_self_cd g0120a_bathg_self_cd g0110i1_toiltg_self_cd g0110h1_eatg_self_cd
capture label define lbl_act 0"independent"  1"supervision"  2"limited assistance"  3"extensive assistance"  4"total dependence" ///  
7"activity occurred once/twice" 8"activity did not occurr"

foreach x in g0110g1_dress_self_cd g0110j1_prsnl_hygne_self_cd g0120a_bathg_self_cd g0110i1_toiltg_self_cd g0110h1_eatg_self_cd {
	destring `x', replace force
	label values `x' lbl_act
}

/*
foreach x in g0110g1_dress_self_cd g0110j1_prsnl_hygne_self_cd g0120a_bathg_self_cd g0110i1_toiltg_self_cd g0110h1_eatg_self_cd {

	replace `x'=.  if `x'>=7 
}
*/

* Self-care measures ared coded the same way as mobility measures - see tech specs
* replace records for which activity did not occurr or occurred only once/twice as missing (so will not included in descr stats and reg)

label define new_var_lab 0"independent/supervision/limited assistance"  1"extensive ass/total dependence"

*ppppppppppppppppppppppppppppp*
cap program drop selfcare_inputs
program define selfcare_inputs
args new_var old_var
	
	replace `old_var'=. if `old_var'>=7
	gen `new_var'=.
	replace `new_var'=1 if `old_var'>=3 & `old_var'<.
	replace `new_var'=0 if `old_var'<3
	tab `new_var' `old_var', m
	label values `new_var' new_var_lab  
end

*ppppppppppppppppppppppppppppp*

selfcare_inputs dress_assist g0110g1_dress_self_cd 
selfcare_inputs hyg_assist g0110j1_prsnl_hygne_self_cd 
selfcare_inputs bath_assist g0120a_bathg_self_cd 
selfcare_inputs toilt_assist g0110i1_toiltg_self_cd 
selfcare_inputs eat_assist g0110h1_eatg_self_cd

gen selfcare_comp=dress_assist+hyg_assist+bath_assist+toilt_assist+eat_assist

tab selfcare_comp


save Data\pac_clean_2011_2014.dta, replace

******************************************************
******************************************************
* Combine MDS and ANALYTIC FILE 
******************************************************
******************************************************
/*
*Exploring duplicates
use data\mds_asmt311_r4396, clear
* keep only 5-day assessments
keep if a0310b_pps_cd=="01"  

duplicates report bene_id trgt_dt
duplicates tag bene_id trgt_dt, gen(dupli)
*/

*Dropping duplicates in each dataset
*PAC dataset
use Data\pac_clean_2011_2014.dta, clear 
duplicates report
*Very few duplicates
duplicates report bene_id trgt_dt
*0.02 % of observations are duplicate
duplicates drop bene_id trgt_dt, force
save Data\pac_clean_2011_2014.dta, replace

*import excel "Data\UpdatedMSDRGGroups_20150818_xWalk.xlsx", firstrow clear
*save "Data\UpdatedMSDRGGroups_20150818_xWalk", replace

*Claims data
*Extracting prior utilizations variables, treatment and control identifiers from the latest analytic file
*use "Data\did_2015_04_msr15_wADDED_DATE.dta", clear   *Original 
use "S:\Shared\David Ruiz\PAC\did_2015_04_msr15_wADDED_DATE.dta", clear


cap drop _merge
*Meging that data with the file that was put together to execute the PAC analys
*MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
merge 1:1 clm_id using  "S:\Shared\AShangraw\data\2015_07\compressedFull\Did_2015_07_msr15", keepusing(twh_* prir_yr_* bene_entlmt_rsn_orig HBPCIC HCONTC HBPCIX HCONTX)
keep if _merge==3
*MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

***************************************************
* Create Indicator Variables From OREC 
***************************************************
rename bene_entlmt_rsn_orig orec
destring orec, replace
gen disabled = orec==1
gen esrd = orec==2
gen dis_esrd = orec==3
	
*Adding MSDRGs
capture drop _merge
*MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
*merge m:1 clm_drg_cd using Data\UpdatedMSDRGGroups_20150818_xWalk, keepusing(clm_drg_group)	*ORIGINAL 
merge m:1 clm_drg_cd using  "S:\Shared\David Ruiz\PAC\UpdatedMSDRGGroups_20150818_xWalk.dta", keepusing(clm_drg_group)




tab clm_drg_cd if _merge==1
*MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
keep if _merge==3
drop _merge
drop twh_anyhemo_1- twh_sevprsrulcer_25
*Note that claims with drg codes of "no payment" will be excluded from the analysis. 
drop if clm_drg_group=="nopayment"|clm_drg_cd=="000"
tab clm_drg_group, gen(new_drg_)

**merging claims to MDS data
*assert clm_thru_dt ==nch_bene_dschrg_dt
*Around 99% of records have the same clm_thr_dt and discharge dates. If they
*are different is because nch_bene_dschrg_dt is missing
*recommend using clm_thru_dt
replace  nch_bene_dschrg_dt=clm_thru_dt if nch_bene_dschrg_dt==.&clm_thru_dt!=.
duplicates report
duplicates report bene_id nch_bene_dschrg_dt
duplicates tag bene_id nch_bene_dschrg_dt, gen(dupli)
duplicates drop bene_id nch_bene_dschrg_dt, force
*list bene_id nch_bene_dschrg_dt clm_from_dt clm_thru_dt if dupli==1, sepby(bene_id)
*There is tiny number of duplicate records 0.02% of the sample. Policy for now is to drop those records
*Many of this duplicates have a different clm_from_dt
capture drop _merge

*MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
joinby bene_id using Data\pac_clean_2011_2014.dta
*MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM


*************************************************************************************************
*Organizing data for the analysis
*looking at inpatients who were admitted to any SNF, 30 days within the hospital discharge date
**************************************************************************************************
*************************************************************************************************
desc nch_bene_dschrg_dt trgt_dt
rename trgt_dt target_dt

* if admission date (target date)occurs 30 days after the discharge date, then:

* Step-1: Keeeping only observation with an MDS assessment within 30 days of 
*an inpatient discahrge

gen dsch_dt_30=nch_bene_dschrg_dt +30
format dsch_dt_30   %td
browse nch_bene_dschrg_dt  dsch_dt_30

*Number of assessments that happen within 30 days of discharge
count if (dsch_dt_30 >= target_dt & target_dt>=nch_bene_dschrg_dt)
keep if (dsch_dt_30 >= target_dt & target_dt>=nch_bene_dschrg_dt)
browse nch_bene_dschrg_dt  target_dt  dsch_dt_30 

/*
* Sara's QA checks
gen year_adm=year(target_dt)
tab year_adm, m
gen year_disch=year(nch_bene_dschrg_dt)
tab year_disch, m
tab year_disch year_adm, m
tab target_dt if year_disch==2010 & year_adm==2011, m
tab target_dt if year_disch==2011 & year_adm==2012, m
tab target_dt if year_disch==2011 & year_adm==2012, m
tab target_dt if year_disch==2012 & year_adm==2013, m
drop year_disch year_adm
* ok
*/

duplicates report bene_id nch_bene_dschrg_dt target_dt
*ok. 

*STEP-2: Keeping the assessment closest to the inpatient discharge
*Counting the total number of MDS assessments a bene has within 30 days of one ip discharge
bysort bene_id target_dt: gen bene_count2 =_N
tab bene_count2,m
sort bene_id target_dt nch_bene_dschrg_dt
*Situation: Multiple discharges and only one assessment in the 30 day window

br bene_id clm_from_dt nch_bene_dschrg_dt target_dt bene_count2 if bene_count2>1

*Sorting benes and assessment dates and numbering the assessments. The command below
*gives the higher _n to the assessment closer to the discharge date  
bysort bene_id target_dt (nch_bene_dschrg_dt): gen bene_count3 =_n
sort bene_id target_dt nch_bene_dschrg_dt
tab bene_count3,m

br bene_id clm_from_dt nch_bene_dschrg_dt target_dt bene_count2 bene_count3

*keeping  closest hospital discharge date to  SNF target date (latest discharge)

keep if bene_count2==bene_count3
duplicates report bene_id target_dt

* the unit of observation is the bene/target date
 
*BPCI vars
*for factor var use
*	egen qtr = group(quarter)
*	egen pvdr = group(prvdr_num)

* gen     post = 0
* replace post = 1 if qtr > 9 & !inlist(prvdr_num,"170183","340049","050708","520196","050697")
* replace post = 1 if qtr > 12 & inlist(prvdr_num,"170183","340049","050708","520196","050697")
	
	*fix HBPCI
*replace HBPCI = 0 if HBPCI ==99
*gen treat_post = HBPCI*post
*tab treat_post
	

*Descriptive Statistics of Outcomes

sum painNQF  pain_sleep mob_assist falls_30days  selfcare_comp 
*BPCI hospitals before
sum painNQF  pain_sleep mob_assist falls_30days  selfcare_comp if post==0&HBPCI==1
*BPCI hospitals  after
sum painNQF  pain_sleep mob_assist falls_30days  selfcare_comp if post==1&HBPCI==1

*Control hospitals before
sum painNQF  pain_sleep mob_assist falls_30days  selfcare_comp if post==0&HBPCI==0
*Control hospitals  after
sum painNQF  pain_sleep mob_assist falls_30days  selfcare_comp if post==1&HBPCI==0

	
*sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss
save Data\pac_analytic, replace
*sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss

use Data\pac_analytic, clear
preserve
keep if HBPCIC==1 | HCONTC==1
tab1 HBPCIC HCONTC
save Data\pac_analytic_actives, replace

restore
preserve
keep if HBPCIX==1 | HCONTX==1
tab1 HBPCIX HCONTX

save Data\pac_analytic_exits, replace


*Defining control variables that will go in the regressions
*Regression controls
*[] Annual report controls - DR's code
global othercontrol "age gender raceBlack raceHisp raceOther dual hcc_score hccmiss drg_weight"
*[] New demographic controls: age0_64 is the omitted category
global newdemo "age65_74 age75_84 age85up gender raceBlack raceHisp raceOther" 
*[] All cc flags
global all_cc "d_alzh_comb d_ami d_asthma d_atrial_fib d_cancer d_chf d_copd d_diabetes d_hip_fracture d_hypoth d_depression d_stroke_tia d_anemia d_cataract d_chronickidney d_glaucoma d_hyperl d_hyperp d_hypert d_ischemicheart d_osteoporosis d_ra_oa"
*[] ICD9 variables 
global icd9vars "twh_anyhemo twh_anyvent twh_tpntransf twh_clinemngt twh_sevprsrulcer"
*Entitlement 
global orec "disabled esrd dis_esrd"
*Past year utilization
global prior_yr "prir_yr_acute_stays prir_yr_snf_gt_30days prir_yr_total_medicare_pmt"
  
*[] 4.b	Total payments from prior year AND inpatient stays AND dummy indicating if SNF covered days > 30; no drg_weight - This is the model IMPAQ suggests we estimate for the next AR
global model6pl_4b $newdemo $all_cc $icd9vars new_drg_2-new_drg_36 $orec  $prior_yr  //drg dummy variables might change depending on the number of categories we have

use Data\pac_analytic, clear

sum $othercontrol
sum $newdemo 
sum $all_cc 
sum $icd9vars 
sum $orec
sum new_drg_* //This part might need updating if we add new drg codes
sum $prior_yr

*PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
*Programs to estimate regressions
*Logit DID first regression
cap program drop did_logit_1
program define did_logit_1
args measu pop date 
	logit `measu' treat_post i.pvdr i.qtr $model6pl_4b , vce(cluster hosp_qrt) or
	outreg2 treat_post $model6pl_4b using results/PAC_DID_`pop'`date'.doc, dec(3) replace ctitle(`measu') eform
end


*Logit DID
cap program drop did_logit
program define did_logit
args measu pop date 
	logit `measu' treat_post i.pvdr i.qtr $model6pl_4b , vce(cluster hosp_qrt) or
	outreg2 treat_post $model6pl_4b using results/PAC_DID_`pop'`date'.doc, dec(3) append ctitle(`measu') eform
end

*LRM DID
cap program drop did
program define did
args measu pop date 
	regress `measu' treat_post i.pvdr i.qtr $model6pl_4b , vce(cluster hosp_qrt)
	outreg2 treat_post $model6pl_4b using results/PAC_DID_`pop'`date'.doc, dec(3) append ctitle(`measu')   
end

*PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

did_logit_1 	painNQF 		all 	090415
did_logit 		pain_sleep 		all 	090415
did_logit 		mob_assist 		all 	090415  
did_logit 		falls_30days 	all  	090415
did 			selfcare_comp 	all 	090415

*actives

use Data\pac_analytic_actives, clear

sum $othercontrol
sum $newdemo 
sum $all_cc 
sum $icd9vars 
sum $orec
sum new_drg_* //This part might need updating if we add new drg codes
sum $prior_yr

did_logit_1 	painNQF 		actives 	090415
did_logit  		pain_sleep 		actives 	090415
did_logit 		mob_assist 		actives 	090415  
did_logit 		falls_30days 	actives 	090415
did 			selfcare_comp 	actives 	090415

*exits

use Data\pac_analytic_exits, clear

sum $othercontrol
sum $newdemo 
sum $all_cc 
sum $icd9vars 
sum $orec
sum new_drg_* //This part might need updating if we add new drg codes
sum $prior_yr

did_logit_1 	painNQF 		exits 	090415
did_logit 		pain_sleep 		exits 	090415
did_logit 		mob_assist 		exits 	090415  
did_logit 		falls_30days 	exits 	090415
did 			selfcare_comp 	exits 	090415

