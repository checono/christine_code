/****
Name: Christine Herlihy
Objective: Consolidate code produced for 2014 AR

Data Pop:
			All 24 BPCI hospitals and 4 matched controls for each hospital.
			There is one control that is matched to three BPCI hospitals
			and 12 controls that are matched twice for a total of XX unique 
			controls.
			
			-->Matched 2x:
				50125,70025,70028,70034,110010,250141,310009,330046,330198,
				340032,410007,520013
				
			--> Matched 3x:
			490057
			
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
			
David Ruiz's notes:
** This is an extension of the SF Report submitted in Feb 2015 and will be used for the AR revision.  
** The only difference from AR results is that it drop the singular comparison hospital.
****/

clear all
estimates clear
set more off
set matsize 10000


*ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
************************* DEFINE GLOBAL MACROS *********************************
*ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd

*CH notes: data version, data location, deposit location, and measure name 
*holder are the same across ALL variables in the original do files; 
*the date and note fields are NOT. The "date" and "note" fields are ONLY used to 
*name the log files associated with each original do file. Thus, since we are 
*merging all these do files, we don't need to preserve unique date or note 
*identifiers; a single (new) one of each will suffice.

* SET DATA VERSIson
	global dataVer "2015_10"
* ANALYTICAL DATA LOCATION 
	global baseData "S:\Shared\AShangraw\data/${dataVer}/compressed"
* SET DATE
	global date "2016_01_07"
* SET DATASET/LOG NOTES
	global note "AR_2_Merged_v2"
* SET DATA DEPOSIT LOCATION
	global  intirim   "S:\Shared\AShangraw\data/${dataVer}/compressed\output\intirim"  
* SET DATA DEPOSIT LOCATION
	global  outputDir   "S:\Shared\AShangraw\data/${dataVer}/compressed\output"   
* INIT MEASURE NAME HOLDER
	global meas ""
	

*ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd*
**************DEFINE REGRESSION SPECIFICATIONS **********************************
*ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd*

*CH notes: original specification, new demographic controls, all cc flags, 
*original reason for entitlement, orec, icd9vars, and newDRG are the same across
*ALL variables in the original do files.

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

*CH notes: In the original do-files, this section corresponds to the "important
*local macros" section/content. Here, we are looping through all possible measures;
*in the original do-files; all but one measure are typically commented out.

*Each measure had its own contents for the local macro "allGroups" in the original
*do-files; this list is exhaustive in that it contains all cohorts AND all 
*individual hospital IDs. 

*12/7/15
**Unclear to me @ present if it is ok to run this local macro without 
*some sort of switch statement, as it seems some variables are not intended
*to be calculated at the hospital level, and some are not intended to be 
*calculated at the cohort level. (??) David said this is not a problem. 


*measure list
	local  nlist 2 7 14 15 16 18 22 90
	/*
		*2 --> mortality
		*81,82,83 --> condition specific mortality
		*7 --> readmissions
		*9,10,11 --> condition specific readmissions
		*14 --> any icu stay and icu days
		*15 --> length of stay
		*16 --> 
		*18 --> post-episode payments and utilization measures
		*22 --> episode payments
		*90 --> CH: added this one; was originally 80 but 80 was alrady in selectData.ado
	*/	
	
*level of analyses
	//local allGroups "all actives exits phc 310108	310014	310051	310010	310050	310038	310044	310096	310073	310070	310092	310019	310015	310005	310006	310069	310032	310110	310111	310012	310081	310031	310024	170183"
	
	*12/17: I tried to run this on only phc but the los model was problematic. am trying again and running only @ the hospital level
	//local allGroups "phc"
	
	//local allGroups "310108	310014	310051	310010	310050	310038	310044	310096	310073	310070	310092	310019	310015	310005	310006	310069	310032	310110	310111	310012	310081	310031	310024	170183"
	local allGroups "actives"
	
	
*ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
*** FINAL MODEL specification is in covariates MACRO
*ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd

*CH notes: this macro is the same across all original do files 
	
	global covariates $demo2 $cc_flgs $icd9vars
	
*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
*** do NOT changes this path
*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
	
*CH notes: the adopath is the same across all original do files 

	adopath ++ "S:\Shared\David Ruiz\ado"

*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
*** load all Regression Models
*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
	
*CH notes: this step is the same across all original do files 
	
	do "S:\Shared\David Ruiz\unsorted\ar15\ar15_initModels_151001.do"

*m set output directory

	*CH notes: output directory the same across all original do files 
	cd ${outputDir}

*m initiate log

	*CH notes: log file differed for each original do file; here, we want one unified log
	capture log close
	log using "ar2015_${date}_${note}", replace 
	
*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
/*
	
*CH notes: Originally, each separate do-file selected only one var from the nlist,
and then selected the appropriate level(s) of analysis; there was no need to 
loop through level(s) of analysis because each var's local macro "allGroups" 
content was different. Here, ALL measures are included in nlist and we are 
looping through nlist, selecting the appropriate level of analysis and dataset
for each measure, looping through sub-measures, and running associated models.

Most of the variables only have one set of models associated with them, so we 
can essentially set up a switch structure to iterate. However, var 18 has two 
do-files (and thus, two different levels of analysis and sets of models) 
associated with it, so we need a sub-switch for each one.

	
	MAIN STEPS
    (1) LOOP through each measure in NLIST
	(2) select the correct level(s) of analysis for each measure
	(3) selectData DiD data set for the appropriate measure
	(4) LOOP through any SUB-measure
	(5) 
*/
*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm

foreach d of local nlist {
	estimates clear
/*	
	if(`d' == 90)
	
	{
		*CH notes: the do-file for n==80 comments out the "use ado" line and subs
		*in these commands:
		use "S:\Shared\AShangraw\data\2015_10\compressed\DID_2015_10_MORT_PSD.dta", clear
		global meas = "mout"
		rename analysis_variable_all ${meas}
	}
	
	else
	{
		
	*/	
		* Select the appropriate dataset
		*CH notes: all original do-files use selectData ado except for n==80. 
		selectData_CH `d'
	
	
	disp "CURRENT MEAUSRE NUMBER IS # `d' NAMED ${meas}"
	

	* General Data Clean Up, ULTIMATELY, i will move everything in the qui{} to the initiating compression code
	*CH comment: this qui loop is identical for all original do files.
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
		
qui{
*ppppppppppppppppppppppppppppppppppppppppp
*** I STILL NEED TO UPDATE MSR 18, 14, 22
*** FOR THIS NEXT IF SEGMENT
*ppppppppppppppppppppppppppppppppppppppppp

	*CH comments: In every original do-file EXCEPT the ones where 18 is NOT commented out,
	*the first line of sub-measures are created. Measure 18 is active (i.e. not commented out)
	*in two of the original do-files: (1) ar15_master_151015_MS18 and (2) ar15_master_151015_MS18_SNFstaystpm
	*Do-file (1) creates sub-measure "_snf" and do-file (2) creates sub-measure "n_snf"; both are created here; others are commented out
	if inlist(`d',18) {
		//local vlist $meas ${meas}_readm ${meas}_ltchs ${meas}_notrl ${meas}_car ${meas}_snf ${meas}_hsp ${meas}_hha ${meas}_out
		*local vlist $meas ${meas}_readm ${meas}_ltchs ${meas}_notrl ${meas}_car ${meas}_snf ${meas}_hsp ${meas}_hha ${meas}_out ${meas}_n_snf
		local vlist $meas ${meas}_car ${meas}_snf ${meas}_hsp ${meas}_hha ${meas}_out ${meas}_n_snf
	}	
	
	*CH comments: the sub-measures for measure 22 are the same in each original do-file
	else if inlist(`d',22) {
		local vlist ${meas} ${meas}_hp ${meas}_hp_std ${meas}_hp_ndsct ${meas}_ndsct ${meas}_hp_std_wdsct ${meas}_nhp
	}
	
	*CH comments: The do-file for measure == 14 had ${meas}_days commented out, but every other do-file included it; keeping here but can remove if needed
	*Edit after first run: ${meas}_days throws an error: depvar may not be a factor variable
	else if inlist(`d',14){
		local vlist $meas // ${meas}_days
	}
	
	*CH comments: the only do-file which had a switch option for n==2 was the one in which 2 was not commented out; thus, including here
	*12/16: I uncommented "$meas b/c the model didn't work on the last run; nbreg needs estimates for post..is that what is being created here? 
	else if inlist(`d',2){
		local vlist ${meas}_ih //$meas
	}
	
	*CH comments: No other measures are assigned sub-measures in the original do-files
	else{
		local vlist $meas
	}
}		


	*vlist will get submeasures as well
	*CH these lines are the same across all original do-files 
	foreach v of local vlist{
		foreach z of local allGroups{
			preserve
				global QC 1
				local  QN 1		
		
		
	*sum drg_weight
			
	*identifies the correct cohort or Awardee level group, given d=measure #, v=(sub)measure, and z=group desired 
	*CH these lines are the same across all original do-files 
	selectProviderGroup `d' `v' `z' 		
	
	*CH these lines are the same across all original do-files 
	disp "-================================================================-"
	disp "********** DiD: ${meas} OR `v' for `z' Cohort************"
	disp "-=================================================================-"
	disp "Pre Post Sample sizes"
	tab HBPCI post
	disp "Quarterly Sample Sizes"
	tab HBPCI qtr	
		
	*CH these lines are the same across all original do-files 
	if ${QC} {  //if `QC' prevents certain hospital-level DiD models from runnings
		if inlist(`d',80,81,82,83,85,86,87,88,2,14) {   //if TRUE, then exclude Kansas from mortality and ICU measures
			tab prvdr_num if prvdr_num == "170183"
			tab prvdr_num if CONT170183 == 1
			drop if (prvdr_num == "170183" | CONT170183==1)
		}
	
	/*
	*Commented out in all of the original do-files 
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
	*CH comments: in (1), I added "mout" and "| strpos("`v'", "mpaypost30_n") >0 "
	*to match all of the measures that used model_logit in the original do-files
	*This part is structured like a switch, where the cases are `v'
	if inlist("`v'", "icu","ed30","readmit30","mort", "mort_ih", "mout") | strpos("`v'", "mpaypost30_n") > 0  {
		
		disp "Goes here A"
		
		* Get Descriptives
		createDescriptives `d' `v' `z'
		
		disp "Goes here B"
								
		* Run model
		model_logit `v'
		
		disp "Goes here C"
							
		* Create a data set that holds all of these margins
		createMarginDS `d' `v' `z'
	}
	
	*CH comments: in all the original do-files, los is the only measure that uses this model 
	else if inlist("`v'","los") {
		* Get Descriptives
		createDescriptives `d' `v' `z'

		* Run model
		model_los `v'
							
		* Create a data set that holds all of these margins
		createMarginDS `d' `v' `z'
	}
	
	*CH comments: in all the original do-files, icu_days is the only measure that uses this model 
	else if inlist("`v'","icu_days") {

		capture drop treat_post
		capture gen treat_post = HBPCI*post
		mlogit `dep' i.HBPCI i.post treat_post  i.qtr i.hpid $covariates, vce(cluster hosp_qrt) baseoutcome(0)

		margins treat_post, atmeans predict(outcome(0))
		margins treat_post, atmeans predict(outcome(1))
		margins treat_post, atmeans predict(outcome(2))
		margins treat_post, atmeans predict(outcome(3))						
	}
	
	*CH comments: this section was the same in all original do-files except one, which included the OR statement that is added in here. unclear if it needs to be OR rather than added to "if inlist" group
	*Since the lines for measure 18 comment out the creation of all non-snf variables, it's not clear if this elif block is actually needed or used (??) 
	*else if inlist("`v'", "mpaypost30_allother", "mpaypost30_readm","mpaypost30_car")| inlist("`v'","mpaypost30","mpayinp","mpayinp_hp","mpayinp_nhp","mpayinp_hp_std","mpayinp_hp_ndsct","mpayinp_ndsct","mpayinp_hp_std_wdsct") {
	else if inlist("`v'", "mpaypost30_allother","mpaypost30_car")| inlist("`v'","mpaypost30","mpayinp","mpayinp_hp","mpayinp_nhp","mpayinp_hp_std","mpayinp_hp_ndsct","mpayinp_ndsct","mpayinp_hp_std_wdsct") {
	* Get Descriptives"
		createDescriptives `d' `v' `z'
							
		* Run model
		model_ols `v'
							
		* Create a data set that holds all of these margins
		createMarginDS `d' `v' `z'
	}
	
	*CH comments: all original do-files contained the same set of measures, except one, which added 3, which are included here (mpaypost30_inp_readm, mpaypost30_inp_ltchs, mpaypost_inp_notrl)
	*Since the lines for measure 18 comment out the creation of all non-snf variables, it's not clear if this elif block is actually needed or used (??) 
	*else if inlist("`v'", "mpaypost30_inp_readm", "mpaypost30_inp_ltchs")| inlist("`v'", "mpaypost_inp_notrl", "mpaypost30_ltchs","mpaypost_notrl","mpaypost30_car", "mpaypost30_snf","mpaypost30_hsp","mpaypost30_hha","mpaypost30_out"){
	else if inlist("`v'","mpaypost30_inp_readm","mpaypost30_inp_ltchs","mpaypost_inp_notrl","mpaypost30_car", "mpaypost30_snf","mpaypost30_hsp","mpaypost30_hha","mpaypost30_out"
	
	* Get Descriptives
		createDescriptives `d' `v' `z'

		* Run model
		model_tpm `v'
							
		* Create a data set that holds all of these margins
		createMarginDS `d' `v' `z'
	}	
	
	//The other variable associated with measure 18 (_snf)  appears to have no model associated with it (??)
	
	
		} //END of QC
			
		restore
		} //END of COHORT LOOP
	} //END of MEASURE LOOP

}	//END of Measure loop

log close

*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
*********************************** END   **************************************
*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
	
//CH comments: This was included at the end of the ar15_master_151015_MS18_SNFstaystpm do-file
//No formatted output appears at the end of any other do-file; unclear if it will work with the merged file as it is currently structured above (not sure how/if vars are stored). 

/**/
/*
cd  "S:\Shared\AShangraw\data\2015_10\compressed\output\intirim" 
clear 
append using ra_18_mpaypost30_n_snf_all
append using ra_18_mpaypost30_n_snf_actives
append using ra_18_mpaypost30_n_snf_exits
append using ra_18_mpaypost30_n_snf_phc

save ra_18_snf_days, replace
	gen baseline  = string(rate0, "%9.2fc") + "		" + "(" + string(se0, "%9.2fc") + ")"
	
	gen post_full = string(rate1, "%9.2fc")   + "		"    + "(" + string(se1, "%9.2fc") + ")"
	
	gen post_diff = string(pp_diff_rate, "%9.2fc") +  cond(pp_diff_pval < 0.01, "***", cond(pp_diff_pval<0.05,"**", cond(pp_diff_pval<0.1, "*", ""))) + "		" + "(" + string(pp_diff_se, "%9.2fc") + ")"
    gen post_did  = string(pp_did_rate, "%9.2fc")  +  cond(pp_did_pval < 0.01, "***", cond(pp_did_pval<0.05,"**", cond(pp_did_pval<0.1, "*", ""))) + "		" +  "(" + string(pp_did_se, "%9.2fc") + ")" if HBPCI == 0

	gen post_y1         = string(py1_val_rate, "%9.2fc") + "		" +  "(" + string(py1_val_se, "%9.2fc") + ")"
	gen post_y1_diff    = string(py1_diff_rate, "%9.2fc") + cond(py1_diff_pval < 0.01, "***", cond(py1_diff_pval<0.05,"**", cond(py1_diff_pval<0.1, "*", ""))) + "		" +  "(" + string(py1_diff_se, "%9.2fc") + ")"
	gen post_y1_did     = string(py1_did_rate, "%9.2fc")  + cond(py1_did_pval  < 0.01, "***", cond(py1_did_pval <0.05,"**", cond(py1_did_pval <0.1, "*", ""))) + "		" +  "(" + string(py1_did_se, "%9.2fc") + ")"  if HBPCI == 0
				
	gen post_y2   		= string(py2_val_rate, "%9.2fc") + "		" +  "(" + string(py2_val_se, "%9.2fc") + ")"
	gen post_y2_diff    = string(py2_diff_rate, "%9.2fc") + cond(py2_diff_pval < 0.01, "***", cond(py2_diff_pval<0.05,"**", cond(py2_diff_pval<0.1, "*", ""))) + "		"+  "(" + string(py2_diff_se, "%9.2fc") + ")"
	gen post_y2_did     = string(py2_did_rate, "%9.2fc")  + cond(py2_did_pval  < 0.01, "***", cond(py2_did_pval <0.05,"**", cond(py2_did_pval <0.1, "*", ""))) + "		"+  "(" + string(py2_did_se, "%9.2fc") + ")" if HBPCI == 0
			
gsort  -HBPCI
gen typez = "Control"
replace typez = "HBPCI" if HBPCI == 1
global tableName SNF_Visits
cd "S:\Shared\AShangraw\data\2015_10\compressed\tables\"

local plist all actives exits phc
foreach p of local plist{
	local s 3
		preserve
			keep if cohort == "`p'"
			local len = _N
			
				putexcel C`s'=("Measure") D`s'=("Cohort") E`s'=("Baseline") F`s'=("BPCI Year 1 & 2") G`s'=("BPCI Y12 Diff") H`s'=("DiD") I`s'=("BPCI Year 1") J`s'=("BPCI Year 1 Difference") K`s'=("BPCI Year 1 DiD") L`s'=("BPCI Year 2") M`s'=("BPCI Year 2 Difference") N`s'=("BPCI Year 2 DiD") using ${tableName}, sheet("`p'") modify 
				local s = `s'+1
			forval i = 1/`len'{
				putexcel C`s'=(ms_actual[`i']) D`s'=(typez[`i']) E`s'=(baseline[`i']) F`s'=(post_full[`i']) G`s'=(post_diff[`i']) H`s'=(post_did[`i']) I`s'=(post_y1[`i']) J`s'=(post_y1_diff[`i']) K`s'=(post_y1_did[`i']) L`s'=(post_y2[`i']) M`s'=(post_y2_diff[`i']) N`s'=(post_y2_did[`i']) using ${tableName}, sheet("`p'") modify 
				local s = `s' + 1
			}
		restore
}
	

*/
	
	
	
	
	
		
		
		
		
	
	
	
