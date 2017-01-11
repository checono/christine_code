set more off , perm
set matsize 10000
set rmsg on
clear all
cd "S:\Shared\ARNV\OY\OY2\ITT\"

global date "20160412"

cap log close
set logtype text
log using OY2_ITT_22_CHedits_v3_${date}.txt, replace

use "S:\Shared\AShangraw\data\2015_07\compressedFull\DID_2015_07_MSR22_SPLIT.dta", clear

*sample 10

*Ado directory
*sysdir set PERSONAL dza710:\ado\
*or
adopath + "S:\Shared\ARNV\ado"


*Regression controls
*[] Annual report controls - DR's code
global othercontrol "age gender raceBlack raceHisp raceOther dual hcc_score hccmiss drg_weight"
*[] New demographic controls: age0_64 is the omitted category
global newdemo "age65_74 age75_84 age85up gender raceBlack raceHisp raceOther" 
*[x]All cc flags
global cc_flgs "d_alzh_comb d_ami d_asthma d_atrial_fib d_cancer d_chf d_copd d_diabetes d_hip_fracture d_hypoth d_depression d_stroke_tia d_anemia d_cataract d_chronickidney d_glaucoma d_hyperl d_hyperp d_hypert d_ischemicheart d_osteoporosis d_ra_oa"
*OREC
global orec "disabled esrd dis_esrd"
*[] ICD9 variables 
* exclude missing twh_*_mi
global icd9vars "twh_anyhemo twh_anyvent twh_tpntransf twh_clinemngt twh_sevprsrulcer "
global other "dual  prir_yr_total_medicare_pmt prir_yr_acute_stays prir_yr_snf_gt_30days"
global newDRG "new_drg_2-new_drg_36" 

global demo2 "age65_74 age75_84 age85up gender raceBlack raceHisp raceOther hcc_score hccmiss ln_drg dual" 

global covariates $demo2 $cc_flgs $icd9vars 

gen ln_drg=ln(alt_drg_weight)

gen disabled =(bene_entlmt_rsn_orig =="1")
gen esrd =(bene_entlmt_rsn_orig =="2")
gen dis_esrd=(bene_entlmt_rsn_orig =="3")

*start getting results for each sub sample
gen active=(HBPCIC==1 | HCONTC==1)
gen exits=(HBPCIX==1 | HCONTX==1)
gen expan=(HBPCIE==1 | HCONTE==1)
gen targ=(HBPCIT==1 | HCONTT==1)
gen PHC=(HBPCIPHC==1 | HCONTPHC==1)
gen all=1

gen hbpci=(HBPCIC==1 | HBPCIX==1)

*Program Year
gen PY=0
replace PY=1 if qtr==10 | qtr==11 | qtr==12 | qtr==13
replace PY=2 if qtr>13 
replace PY=0 if  (qtr==10 | qtr==11 | qtr==12) & (pvdr==5 | pvdr==6 | pvdr==30 | pvdr==80 | pvdr==106)
replace PY=1 if  (qtr==13 | qtr==14 | qtr==15 | qtr==16) & (pvdr==5 | pvdr==6 | pvdr==30 | pvdr==80 | pvdr==106)
replace PY=2 if  (qtr==17) & (pvdr==5 | pvdr==6 | pvdr==30 | pvdr==80 | pvdr==106)

rename analysis_variable_all mpayinp 
rename analysis_variable_nhp mpayinp_nhp
rename analysis_variable_car mpayinp_car
rename analysis_variable_out mpayinp_out
rename analysis_variable_dme mpayinp_dme
rename analysis_variable_all_std std_mpayinp
rename analysis_variable_nhp_std std_mpayinp_nhp
rename analysis_variable_car_std std_mpayinp_car
rename analysis_variable_out_std std_mpayinp_out
rename analysis_variable_dme_std std_mpayinp_dme
rename n_index_hospital n_hp
rename n_non_hospital n_nhp
rename n_carrier n_car
rename n_outpatient n_out
rename n_dme n_dme
rename n_total n_all

gen ln_mpayinp=ln(mpayinp)
gen ln_mpayinp_nhp=ln(mpayinp_nhp)
gen ln_mpayinp_car=ln(mpayinp_car)
gen ln_mpayinp_out=ln(mpayinp_out)
gen ln_mpayinp_dme=ln(mpayinp_dme)

***************************************************************
*Merge with BPCI participation
***************************************************************
* Drop KS hospital until PQ9
drop if prvdr_num=="170183" | prvdr_num=="340049" | prvdr_num=="050708" | prvdr_num=="520196" | prvdr_num=="050697"

*keep  quarter hbpci pvdr qtr PY hosp_qrt org_npi_num at_physn_npi op_physn_npi ot_physn_npi bene_id clm_id prvdr_num active exits expan targ PHC all post

*destring attending NPI number
destring at_physn_npi , replace

*PQ5 = 2q2014
******************
*need to make quarter_v2 (to fit using data)
split quarter , parse("-")
rename quarter1 year 
destring year, replace
destring quarter2, replace
gen qdate = yq(year, quarter2)
format qdate %tq
rename qdate quarter_v2
drop year quarter2
tab quarter_v2

drop if quarter_v2 > tq(2014q2)
merge m:1 quarter_v2 prvdr_num at_physn_npi using "S:\Shared\ARNV\OY\OY2\ITT\bpci_particip_rule24_PQ5_m.dta"

*merge==2 means listed in the BPCI program but no npi matched to
*merge==3 are docs who are not in BPCI (thus no match)
drop if _merge==2
drop _merge
replace BPCI=0 if BPCI==.
sort quarter_v2 prvdr_num at_physn_npi
order  BPCI prvdr_num quarter_v2 at_physn_npi hbpci

*******************************
*make Head Count of BPCI docs *
*******************************
sort quarter_v2 prvdr_num at_physn_npi
*w is just a counter equal to 1 at the first BPCI obs per qtr, hosp
by quarter_v2 prvdr_num at_physn_npi: gen w=1 if BPCI==1 & _n==1
*t cunts how many NPIs by qtr, prvdr
by quarter_v2 prvdr_num at_physn_npi: gen t=1 if  _n==1
by quarter_v2 prvdr_num: egen BPCI_HC_N=sum(w)
by quarter_v2 prvdr_num: egen BPCI_HC_D=sum(t)
gen BPCI_HC=BPCI_HC_N/BPCI_HC_D
drop w t BPCI_HC_N BPCI_HC_D

****************************************
*make Case weighted count of BPCI docs *
****************************************
* now need patient weighted measure 
* by quarter_v2 prvdr_num at_physn_npi: 
distinct clm_id
sort quarter_v2 prvdr_num at_physn_npi
by quarter_v2 prvdr_num at_physn_npi: egen DR_case_count=count(clm_id)
by quarter_v2 prvdr_num: egen DR_case_T=count(clm_id)
gen DR_BPCI_case_count=DR_case_count*BPCI
order DR_BPCI_case_count DR_case_count DR_case_T BPCI prvdr_num quarter_v2 at_physn_npi hbpci
*first number is kept rest are missing values
by quarter_v2 prvdr_num at_physn_npi: gen t = DR_BPCI_case_count if _n==1
*u is fully filled out count of cases by BPCI docs in a hospital and qtr
by quarter_v2 prvdr_num: egen u = sum(t)
*populate case weighted avg accross qtr provider 
gen BPCI_case=u/DR_case_T
drop t u  DR_BPCI_case_count DR_case_count DR_case_T
gen check_BPCI = BPCI_HC - BPCI_case

sum BPCI_HC if BPCI_HC>0 , d 
sum BPCI_case if BPCI_case>0 , d
sum check_BPCI  , d
*check
tab BPCI_case treat_post
sum  BPCI_HC if quarter_v2 < tq(2013q2) //should be zeros
*********************************************************************************************
/*
tab pvdr , gen(ipvdr)
tab qtr , gen(iqtr)

foreach w in all active exits PHC expan targ {
preserve
display "Sample is `w'"
keep if `w'==1

*Get baseline estimate of standard model
regress  mpayinp i.hbpci i.post treat_post i.pvdr i.qtr $covariates , vce(cluster hosp_qrt) 
eststo AR_lLN_`w'_b
*head count 
regress  mpayinp i.hbpci i.post BPCI_HC i.pvdr i.qtr $covariates , vce(cluster hosp_qrt) 
eststo AR_lLN_`w'_HC
*Case count 
regress  mpayinp i.hbpci i.post BPCI_case i.pvdr i.qtr $covariates , vce(cluster hosp_qrt) 
eststo AR_lLN_`w'_case
*doc is in BPCI and in treatment period
regress  mpayinp i.hbpci i.post BPCI i.pvdr i.qtr $covariates , vce(cluster hosp_qrt) 
eststo AR_lLN_`w'_BPCI

regress  mpayinp i.hbpci i.post i.BPCI#i.qtr i.pvdr i.qtr $covariates , vce(cluster hosp_qrt) 


*BPCI doc and co-workers case weighted in BPCI
regress  mpayinp i.hbpci i.post BPCI BPCI_case i.pvdr i.qtr $covariates , vce(cluster hosp_qrt) 
eststo AR_lLN_`w'_BPCI_HC
*BPCI doc and co-workers head count in BPCI
regress  mpayinp i.hbpci i.post BPCI BPCI_HC i.pvdr i.qtr $covariates , vce(cluster hosp_qrt) 
eststo AR_lLN_`w'_BPCI_case

gen BPCI_case2=BPCI_case^2
regress  mpayinp i.hbpci i.post BPCI BPCI_case BPCI_case2 i.pvdr i.qtr $covariates , vce(cluster hosp_qrt) 
eststo AR_lLN_`w'_BPCI_case2



estout AR_lLN_`w'_b AR_lLN_`w'_HC AR_lLN_`w'_case AR_lLN_`w'_BPCI, cells(b(star fmt(3)) se(par fmt(2)) ) stats(aic bic N) starlevels(* 0.10 ** 0.05 *** 0.01)
estout AR_lLN_`w'_b AR_lLN_`w'_BPCI AR_lLN_`w'_BPCI_HC AR_lLN_`w'_BPCI_case AR_lLN_`w'_BPCI_case2 , cells(b(star fmt(3)) se(par fmt(2)) ) stats(aic bic N) starlevels(* 0.10 ** 0.05 *** 0.01)

restore
}



******************************************
*COLLAPSE to HQ level
foreach w in all active exits PHC expan targ {
preserve
display "Sample is `w'"
keep if `w'==1

sort pvdr qtr
collapse (mean)   mpayinp treat_post post hbpci $covariates  PY BPCI_HC BPCI_case all active exits PHC expan targ , by(pvdr qtr)
gen hosp_qtr=10000*pvdr + qtr
******************************************


* 2-period model (no time dimension)
regress  mpayinp i.hbpci i.post treat_post i.pvdr i.qtr $covariates , vce(cluster hosp_qtr) 
eststo AR_lLN_`w'_HQ

*using BPCI uptake
regress  mpayinp i.hbpci i.post BPCI_HC i.pvdr i.qtr $covariates , vce(cluster hosp_qtr) 
eststo AR_lLN_`w'_HQ_HC
regress  mpayinp i.hbpci i.post BPCI_case i.pvdr i.qtr $covariates , vce(cluster hosp_qtr) 
eststo AR_lLN_`w'_HQ_case

estout AR_lLN_`w'_HQ AR_lLN_`w'_HQ_HC AR_lLN_`w'_HQ_case , cells(b(star fmt(3)) se(par fmt(2)) ) stats(aic bic N) starlevels(* 0.10 ** 0.05 *** 0.01)

restore
}

*/

/*
NOTE: Cannot use factor variables in qreg.
Used dummies generated by tab inside the loop
Cannot have ommited values or grqreg crashes. Thus, manually set them.
*******NOTE: when the data set changes the variables excluded may change
All: Xpvdr101
	exclude: Xqtr14 Xpvdr69  
Active: Xpvdr53
	exclude: Xqtr14 Xpvdr35 
Exits: Xpvdr55
	exclude: Xqtr14 Xpvdr37
PHC: Xpvdr27
	exclude: Xqtr14 Xpvdr16
Expan: Xpvdr34
	exclude: Xqtr14 Xpvdr22
Targ: Xpvdr70
	exclude: Xqtr14 Xpvdr49
*/
global all 		"Xpvdr2-Xpvdr68 Xpvdr70-Xpvdr101 Xqtr2-Xqtr13" 
global active 	"Xpvdr2-Xpvdr34 Xpvdr36-Xpvdr53 Xqtr2-Xqtr13" 
global exits 	"Xpvdr2-Xpvdr36 Xpvdr38-Xpvdr55 Xqtr2-Xqtr13" 
global PHC 		"Xpvdr2-Xpvdr15 Xpvdr17-Xpvdr27 Xqtr2-Xqtr13" 
global expan 	"Xpvdr2-Xpvdr21 Xpvdr23-Xpvdr34 Xqtr2-Xqtr13" 
global targ 	"Xpvdr2-Xpvdr48 Xpvdr50-Xpvdr70 Xqtr2-Xqtr13" 

* all active exits PHC expan targ
*foreach w in all active exits PHC expan targ {
foreach w in exits expan targ {
preserve
display "Sample is `w'"
keep if `w'==1
tab pvdr , gen(Xpvdr)
tab qtr , gen(Xqtr)

* try Q reg
*exclude pvdr 38 and 57 for collinearity
display "Linear model: `w'"
regress  mpayinp i.hbpci i.post BPCI BPCI_case $`w' $covariates , vce(cluster hosp_qrt) 
qreg  mpayinp hbpci post BPCI BPCI_case $covariates $`w' , q(0.5)  nolog 

grqreg BPCI BPCI_case , cons ci ols olsci 
graph export "S:\Shared\ARNV\OY\OY2\ITT\qreg_`w'_BPCI_case_22.png", as(png) replace


lowess mpayinp BPCI_case  , bwidth(0.1)
graph export "S:\Shared\ARNV\OY\OY2\ITT\LOWESS_`w'_BPCI_case_22all.png", as(png) replace
lowess mpayinp BPCI_case if BPCI_case>0 , bwidth(0.1)
graph export "S:\Shared\ARNV\OY\OY2\ITT\LOWESS_`w'_BPCI_case_22pos.png", as(png) replace

restore
}

log close
