/****
Name: David Ruiz
DLU : 15.07.10
Objective:  
			DID stuff

Data Pop:   
			all 24 BPCI hospitals and 4 matched controls for each hospitals.
			There is one control that is matched to three BPCI hospitals
			and 12 controls that are matched twice for a total of XX unique controls.
			
			--> matched 2x: 50125,70025,70028,70034,110010,250141,310009,330046,330198,340032,410007,520013
			--> matched 3x: 490057
Analyses Level:
			[x] Provider Level
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
			[x] Weighted Risk-adjusted Rates
			[x] Diff-in-Diffs
		
			
Addtional Notes:  
** this is an extension of the SF Report submitted in Feb 2015 and will be used for the AR revision.  
** the only difference from AR results is that it drop the singular comparison hospital.

* 04/13/2106: CH- am running this to test margins command on icu DiD dataset; restricted cohort macro to "exits" only (change back later!)
****/
clear all
estimates clear
set more off
set matsize 10000
* set trace on // get stack trace for debugging



*ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
************************* DEFINE GLOBAL MACROS *********************************
*ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
* SET DATA VERSIson
	global dataVer "2015_10"
* ANALYTICAL DATA LOCATION 
	global baseData "S:\Shared\AShangraw\data/${dataVer}/compressed"
* SET DATE
	global date 160422
* SET DATASET/LOG NOTES
	global note AR_14
* SET DATA DEPOSIT LOCATION
	global  intirim   "S:\Shared\AShangraw\data/${dataVer}/compressed\output\intirim"  
* SET DATA DEPOSIT LOCATION
	global  outputDir   "S:\Shared\AShangraw\data/${dataVer}/compressed\output"   
* INIT MEASURE NAME HOLDER
	global meas ""

*ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd*
**************DEFINE REGRESSION SPECIFICATIONS **********************************
*ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd*
*[ ]Original Specification
	global demo1 "age gender raceBlack raceHisp raceOther dual hcc_score hccmiss drg_weight"
*[x]New demographic controls: age0_64 is the omitted category
	global demo2 "age65_74 age75_84 age85up gender raceBlack raceHisp raceOther hcc_score hccmiss lndrg_weight dual" 
*[x]All cc flags
	global cc_flgs "d_alzh_comb d_ami d_asthma d_atrial_fib d_cancer d_chf d_copd d_diabetes d_hip_fracture d_hypoth d_depression d_stroke_tia d_anemia d_cataract d_chronickidney d_glaucoma d_hyperl d_hyperp d_hypert d_ischemicheart d_osteoporosis d_ra_oa"
*[]Orginal Reason for Entitlement dummies
	global orec "disabled esrd dis_esrd"
*[x]ICD9 indicators
	global icd9vars "twh_anyhemo twh_anyvent twh_tpntransf twh_clinemngt twh_sevprsrulcer" //twh_*_mi"
*[]Prior Year Utilization
	global pri_util "prir_yr_total_medicare_pmt prir_yr_acute_stays prir_yr_snf_gt_30days"
*[]IMPAQ DRG Categories
	global newDRG "new_drg_2-new_drg_36" 
	
	
*ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
*********************** IMPORTANT LOCAL MACROS *********************************
*ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
*working folder - meant to be temporary
	*local  intirim "S:\Shared\AShangraw\data\2015_07\compressed\merged\intirim"  //intirim dataset path

*measure list
	local  nlist /*2 7*/ 14 /*15 16 18 22 */
	/*
		*2 --> mortality
		*81,82,83 --> condition specific mortality
		*7 --> readmissions
		*9,10,11 --> condition specific readmissions
		*14 --> any icu stay and icu days
		*15 --> lenght of stay
		*16 --> 
		*18 --> post-episode payments and utilization measures
		*22 --> episode payments
	*/
	
*level of analyses
*	local allGroups "all actives exits phc" //310108	310014	310051	310010	310050	310038	310044	310096	310073	310070	310092	310019	310015	310005	310006	310069	310032	310110	310111	310012	310081	310031	310024	170183"
	local allGroups "actives" //310108	310014	310051	310010	310050	310038	310044	310096	310073	310070	310092	310019	310015	310005	310006	310069	310032	310110	310111	310012	310081	310031	310024	170183"
	

*ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
*** FINAL MODEL specification is in covariates MACRO
*ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
	global covariates $demo2 $cc_flgs $icd9vars
	

*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
*** do NOT changes this path
*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
	adopath ++ "S:\Shared\David Ruiz\ado"

*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
*** load all Regression Models
*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
	do "S:\Shared\David Ruiz\unsorted\ar15\ar15_initModels_151001_CH.do"


capture program drop model_logit2   
program define model_logit2
	args dep  	

	
		if strpos("`dep'","mpaypost30_n") > 0 | "`dep'"== "mpayinp_hasOutlier"{
			capture tab `dep'
			replace `dep' = 0 if missing(`dep')
			replace `dep' = 1 if `dep'>0
			capture tab `dep'
	}
		logit `dep' i.HBPCI i.post i.HBPCI#i.year  i.year i.hpid $covariates, vce(cluster hosp_qrt)
			display "*****************************"
			display "REHASH of YEAR 1 & 2 WITH YEAR FE"
			display "*****************************"
						*DID CoEF & Sig Test for PY1 & PY2
							margins r.HBPCI, over(r.year) noestimcheck //post
								mat didpy_tble = r(table)

								mat list didpy_tble

								
							*PY 1 & PY2 Values
							margins HBPCI, over(year) noestimcheck //post
								mat pyval_tble = r(table)
								
							*PY 1 & PY2 Values
							margins HBPCI, over(r.year) contrast(marginswithin effects) noestimcheck //post
								mat py_tble = r(table)
								
								
							disp "Margins if HBPCI == 1, at(HBPCI =(0 1))"
							*margins if HBPCI == 1, at(year@HBPCI=(0 1)) post
							margins if HBPCI == 1, at(HBPCI=(0 1)) noestimcheck //post
							mat ch_test = r(table)
							mat list ch_test
							
							disp "Margins if HBPCI == 1, at(HBPCI =(0 1))"
							*margins if HBPCI == 1, at(year@HBPCI=(0 1)) post
							margins if HBPCI == 1, at(HBPCI=(0 1)) noestimcheck //post
							mat ch_test = r(table)
							mat list ch_test
							
							disp "Margins if HBPCI == 1, at(year=(1 2))"
							*margins if HBPCI == 1, at(year@HBPCI=(0 1)) post
							margins if HBPCI == 1, at(year=(0 1 2)) noestimcheck //post
							mat ch_test2 = r(table)
							mat list ch_test2
							
							disp "margins if HBPCI == 1, at(year=(0 1 2) HBPCI=(0 1)) noestimcheck"
							margins if HBPCI == 1, at(year=(0 1 2) HBPCI=(0 1)) noestimcheck
							mat ch_test3 = r(table)
							mat list ch_test3
							
							
							disp "margins if HBPCI == 1, over(year) noestimcheck"
							margins if HBPCI == 1, over(year) noestimcheck
							mat ch_test4 = r(table)
							mat list ch_test4
							
							disp "margins if HBPCI == 1, over(r.year) contrast(marginswithin effects) noestimcheck"
							margins if HBPCI == 1, over(r.year) contrast(marginswithin effects) noestimcheck
							mat ch_test5 = r(table)
							mat list ch_test5
							
							
							
			
							*disp "lincom test"
							*lincom 2._at - 1._at	
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
	
	
	
	
	
	
	
	
*m set output directory
	cd ${outputDir}

*m initiate log
	capture log close
	log using "ar2015_${date}_${note}_CHtest", replace 
	
	

*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
/*
	MAIN STEPS
    (1) LOOP through each measure in NLIST
	(2) selectData DiD data set for the appropriate measure
	(3) LOOP through any SUB-measure
	(4) 
*/
*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm

foreach d of local nlist {
	estimates clear
		
	* Select the appropriate dataset
		selectData `d'
	
	disp "CURRENT MEAUSRE NUMBER IS # `d' NAMED ${meas}"

	* General Data Clean Up, ULTIMATELY, i will move everything in the qui{} to the initiating compression code
	qui{
		*for factor var use
		capture tabulate prvdr_num, gen(hospital)
		capture destring prvdr_num, gen(hpid)
	
		capture gen years = substr(quarter,1,4)
		capture tabulate yrs, gen(years)

		*fix HBPCI
		capture replace HBPCI = 0 if HBPCI ==99
		capture gen treat_post = HBPCI*post
		tab treat_post
		tab HBPCI post
	
		*disp "DROP PROBLEMATIC COMPARISON PROVIDER"
		drop if inlist(prvdr_num,"360113")
		*tab drg_weight
		*drop if drg_weight > 30
		gen test=missing(alt_drg_weight) | alt_drg_weight==0
		tab test
		capture drop lndrg_weight
		gen lndrg_weight = ln(alt_drg_weight)

			*****GENERATE "year" VALUES
		capture drop year
		gen year = 0
		replace year = 1 if inlist(qtr, 10,11,12,13) & !inlist(prvdr_num,"170183","340049","050708","520196","050697")
		replace year = 1 if inlist(qtr, 13) & inlist(prvdr_num,"170183","340049","050708","520196","050697")
		replace year = 2 if inlist(qtr,14,15,16,17) //& !inlist(prvdr_num,"170183","340049","050708","520196","050697")
		
	
}
		
		drop if quarter > "2015-1"
		tab quarter
		tab qtr
		
		*sample 1
		
	*save ${intirim}/ch_margins_test_dataToUse, replace
		

qui{


	

	
*ppppppppppppppppppppppppppppppppppppppppp
*** I STILL NEED TO UPDATE MSR 18, 14, 22
*** FOR THIS NEXT IF SEGMENT
*ppppppppppppppppppppppppppppppppppppppppp
	if inlist(`d',18) {
		local vlist $meas ${meas}_readm ${meas}_ltchs ${meas}_notrl ${meas}_car ${meas}_snf ${meas}_hsp ${meas}_hha ${meas}_out
	}	
	else if inlist(`d',22) {
		local vlist ${meas} ${meas}_hp ${meas}_hp_std ${meas}_hp_ndsct ${meas}_ndsct ${meas}_hp_std_wdsct ${meas}_nhp
	}
	else if inlist(`d',14){
		local vlist $meas //${meas}_days
	}
	else{
		local vlist $meas
	}
}

	*vlist will get submeasures as well
	foreach v of local vlist{
		foreach z of local allGroups{
			preserve
				global QC 1
				local  QN 1

				*sum drg_weight
			
				*identifies the correct cohort or Awardee level group, given d=measure #, v=(sub)measure, and z=group desired 
					selectProviderGroup `d' `v' `z' 


				disp "-================================================================-"
				disp "********** DiD: ${meas} OR `v' for `z' Cohort************"
				disp "-=================================================================-"
				disp "Pre Post Sample sizes"
					tab HBPCI post
				disp "Quarterly Sample Sizes"
					tab HBPCI qtr
			
					if ${QC} {  //if `QC' prevents certain hospital-level DiD models from runnings
						if inlist(`d',80,81,82,83,85,86,87,88,2, 14) {   //if TRUE, then exclude Kansas from mortality and ICU measures
							tab prvdr_num if prvdr_num == "170183"
							tab prvdr_num if CONT170183 == 1
							drop if (prvdr_num == "170183" | CONT170183==1)
						}
		/*
					*m: winzoring 1st and 99th percentile for payment measures
					qui{
						if inlist(`d',22){
							sum `v', detail
							gen bclip=r(p1)
							gen tclip=r(p99)
							drop if `v' <= bclip
							drop if `v' >= tclip
							sum `v', detail
						}
						if inlist(`d',18){
							sum `v', detail
							gen bclip=r(p1)
							gen tclip=r(p99)
							drop if `v' <= bclip
							drop if `v' >= tclip
							sum `v', detail
						}
					}
		*/		
					*m: select appropriate model based on Measure and run it yo!
						if inlist("`v'", "icu","ed30","readmit30","mort") {
						
								disp "**** goes to GET DESCRIPTIVES *****"  //Goes here
							* Get Descriptives
								createDescriptives `d' `v' `z'
										
							* Run model
								disp "goes to model_logit"
								model_logit2 `v'
								
								*disp "Option A: margins if HBPCI == 1, at(HBPCI=(0 1))"
                               * margins if HBPCI == 1, at(HBPCI=(0 1)) post
                                                
                              *  disp "lincom test"
                               * lincom 2._at - 1._at
								
					
								disp "Exits model_logit"
							
							* Create a data set that holds all of these margins
								*createMarginDS `d' `v' `z'
						}
						else if inlist("`v'","los") {
							* Get Descriptives
								createDescriptives `d' `v' `z'

							* Run model
								model_los `v'
								
								
							
							* Create a data set that holds all of these margins
								createMarginDS `d' `v' `z'
						}
						else if inlist("`v'","icu_days") {

								capture drop treat_post
								capture gen treat_post = HBPCI*post
								mlogit `dep' i.HBPCI i.post treat_post  i.qtr i.hpid $covariates, vce(cluster hosp_qrt) baseoutcome(0)

								margins treat_post, atmeans predict(outcome(0))
								margins treat_post, atmeans predict(outcome(1))
								margins treat_post, atmeans predict(outcome(2))
								margins treat_post, atmeans predict(outcome(3))						
						}
						else if inlist("`v'","mpaypost30","mpaypost30_car","mpayinp","mpayinp_hp","mpayinp_nhp","mpayinp_hp_std","mpayinp_hp_ndsct","mpayinp_ndsct","mpayinp_hp_std_wdsct") {
							* Get Descriptives"
								createDescriptives `d' `v' `z'
							
							* Run model
								model_ols `v'
							
							* Create a data set that holds all of these margins
								createMarginDS `d' `v' `z'
						}
						else if inlist("`v'","mpaypost30_readm","mpaypost30_ltchs","mpaypost_notrl","mpaypost30_car", "mpaypost30_snf","mpaypost30_hsp","mpaypost30_hha","mpaypost30_out"){
							* Get Descriptives
								createDescriptives `d' `v' `z'

							* Run model
								model_tpm `v'
							
							* Create a data set that holds all of these margins
								createMarginDS `d' `v' `z'
						}					

		} //END of QC
			
	*	restore
		} //END of COHORT LOOP
	} //END of MEASURE LOOP

}	//END of Measure loop

*log close
*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
*********************************** END   **************************************
*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm



