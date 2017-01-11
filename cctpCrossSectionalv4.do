/*
	Created by:DR 
	Last Updated: 15.12.08
	Objective : CCTP Served Beneficiary-Level (Pooled) cross-sectional analysis that used matches from runPSMv5.do for QMD 6 report
				CCTP Bene Identification: treatment (served ==1) and potential control group (served ==0)
				General method requirements: 
				[x] adhere to IMPAQs model as much as possible (LP models, cluster at hospital-provider level)
				[x] regression variables are listed in local macro depVar
				
				Measures assessed: 
				[x] all-cause readmissions, 30-day
				[x] Medicare expenditures, 30-day
				[x] ed and obs visits, 30-day
				
	
	Input     : (CCTP Program) Quarterfiles that contain all beneficiaries from CCTP hospitals and Control/Comparison Eligible beneficiaries
				 Univerisal exclusions applied (at time of creation in SAS) to these files excludes 
					[x] Benes that Died during admission: CC_DENOM_EXCL_EXPIRED
					[x] Benes that had a transfer: FLAG_DENOM_EXCL_LOS_YR
					[x] Benes that had a length of stay > 1 year: CC_DENOM_EXCL_LOS_YR
					[x] Those with discharge from non-acute care hospital: CC_DENOM_EXCL_NON_ACUTE_DSCHRG
					[x] Benes without FFS Coverage in month of discharge: CC_DENOM_EXCL_NO_FFS_AB
				Files:
					[x] servedBeneAnalyticFile  -->  produced by runPSMv5; contains matched cohort (index discharges for served and nonserved) and corresponding
													30-day and 60-day post-(index)discharge measures.
					[x] mSetFull   ---> produced by runPSMv5; contains index discharge and bene information for all persons matched
				  
	Output    : 
				* Excel tables in QDM6 report format and corresponding graphics
	
	Notes     : 
				* Beneficiaries that are actually served by CCTP at CCTP hospitals are identified as 
					program_status=="SERVED" & in_lb  --> served == 1
				* Potential controls are identified as 
					program_status=="CONTROL ELIGIBLE" & missing(served)  --> served == 0
				* CCTP Program quarter starts from Feb 1, 2012; first program quarter identified as 2012_1




*/


*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
* set up data, log, and output folders and other static 
* elements like the data version 
*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
clear all 
set more off

*set data version
global dataVer "2015_10"

global date    "151217"

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

		
adopath + "S:\Shared\David Ruiz\ado"


*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
* set up the measure list, and dependent and indep 
* variables for regression specficiation
*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
global dep "1"
local mlist  readmit //obs ed ppay_total ppay_snf ppay_hha ppay_car ppay_inp ppay_out ppay_hsp ppay_dme
local indepVar dual_qtr snf_disch age male black hisp oth_dk charlindex admissions readmissions los ed_visits_ip ed_visits_op  pay*pre1  imp_hcc_4cctp cc* ami hf pnu copd bdtot admtot vem voth for_profit percent_medicare percent_medicaid cmi  

						
*pppppppppppppppppppppppppppppppppppppppppppppppppppppppp
* this sub-program takes an element from local mlist and 
* selects the corresponding denominator for that measure
* and assigns the outcome variable name to global dep
*pppppppppppppppppppppppppppppppppppppppppppppppppppppppp
capture program drop selectMeasure   
program define selectMeasure
	args m
	
	disp "************************************"
	disp "***Select approrpiate denominator***"
	disp "************************************"
	if ("`m'" == "readmit"){
			*apply denominator exclusion
			keep if readmit_denom_30==1

			*set measure name
			global dep "readmit_30"
		
			*recode to binary
			replace ${dep} = 1 if ${dep} > 0
		}
		else if ("`m'" == "ed"){
			*apply denominator exclusion
			keep if ed_denominator_30==1
	 
			*set measure name
			global dep "ed_admits_30"
	
			*recode to binary
			replace ${dep} = 1 if ${dep} > 0
		}
		else if ("`m'" == "obs"){   
			*apply denominator exclusion
			keep if obs_denominator_30==1
	 
			*set measure name
			global dep  "obs_admits_30"

			*recode to binary
			replace ${dep} = 1 if ${dep} > 0
		}
		else if (substr("`m'",1,4) == "ppay"){   
			*apply denominator exclusion
			keep if flag_denom_30_all == "D"
	 
			*set measure name
			if ("`m'" == "ppay_total"){
				global dep  "total_payment_30"
				/*NOTE: something is not quite right with total_payment_amount_30 --> the original measure variable for combined claim type payments*/
				egen total_payment_30 = rowtotal( payment_carrier_30 payment_dme_30 payment_hha_30 payment_hospice_30 payment_inpatient_index_30 payment_inpatient_other_30 payment_outpatient_30 payment_snf_30)
			}
			else if ("`m'" == "ppay_out"){
				global dep  "payment_outpatient_30"
			}
			else if ("`m'" == "ppay_snf"){
				global dep  "payment_snf_30"
			}
			else if ("`m'" == "ppay_hha"){
				global dep  "payment_hha_30"
			}			
			else if ("`m'" == "ppay_dme"){
				global dep  "payment_dme_30"
			}
			else if ("`m'" == "ppay_hsp"){
				global dep  "payment_hospice_30"
			}			
			else if ("`m'" == "ppay_car"){
				global dep  "payment_carrier_30"
			}
			else if ("`m'" == "ppay_inp"){
				gen payment_inpatient_30 = payment_inpatient_index_30 + payment_inpatient_other_30
				global dep  "payment_inpatient_30"
			}
			*inflation adjustment --> have not verified where IMPAQ got these from
			* 						   and i need to get 2015.  Should probably
			*						  adjust to Medical CPI from FRED. Base year is 2012
			gen tstr = substr(quarter,1,4)
			destring tstr, gen(yr)

			replace ${dep} = ${dep} * 0.985 if yr == 2013
			replace ${dep} = ${dep} * 0.971 if yr == 2014
			replace ${dep} = ${dep} * 0.971 if yr == 2015
			
			drop yr tstr
		}
		
end

	
*pppppppppppppppppppppppppppppppppppppppppppppppppppppppp
* this next section ensures that we still have a one-to-one
* beneficiary match after beneficiariy exclusions occur
* e.g., measure-specific exclusions 
*pppppppppppppppppppppppppppppppppppppppppppppppppppppppp
capture program drop evenSample   
program define evenSample

		disp "***********************************"
		disp "***  ENSURE 1to1 Matched Sample ***"
		disp "***********************************"

		replace ${dep} = 0 if missing(${dep})
		preserve 
			keep if served ==1
			keep bene_id bid* clm_id cid* 
	
			rename bene_id bene_id_t
			rename clm_id clm_id_t
			rename bid_of_match bene_id
			rename cid_of_match clm_id
			save compareCheck, replace
		restore
			merge 1:1 bene_id clm_id using compareCheck, keepusing(bene_id clm_id bene_id_t clm_id_t)
			tab _merge served
			/*
				Case (1): if _merge ==1 --> comparison beneficiary IN analytic file but no longer has its treatment counter part, comparison bene SHOULD be dropped
				Case (2): if _merge ==2 --> comparison beneficiary NOT IN analytic file but still has its treatment counter part, corresponding treatment bene SHOULD be dropped
				Case (3): if _merge ==3 --> it's all good
			*/
   
			*Case (1)
				drop if served == 0 & _merge == 1
				*tab quarter served
			*Case (2)
				preserve 
					keep if served ==0  //& _merge ==2
					
					keep clm_id bene_id   //identify remaining controls
					rename bene_id bid_of_match 
					rename clm_id cid_of_match
				
					disp _N  //should match with _merge ==2 & served ==0 number above
					capture drop _merge
					save compareCheck, replace
				restore
   
				capture drop _merge 
				merge m:1 bid_of_match cid_of_match using compareCheck, keepusing(bid_of_match cid_of_match)
				*tab _merge served
				
				drop if served==1 & _merge == 1
				drop _merge
				
				*tab quarter served
end



*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
/*
  main portion of code below 
	(1) loads the analytic file
	(2) obtains index discharge information
	(3) selects approrpirate measure and "evens" 1-to-1 bene match data accordingly
	(4) rum LPM/OLS models 
	(5) creates interim data sets that contain result information 
		relevant to QDM6 tables and graphics
	(6) creates QDM6 tables in excel
	(7) creates QDM6 graphics
*/
*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm



/*
  (1) & (2) 
  load analytic file that has measures for served and matched beneficiaries
  and merge with index discharge characteristics from mSetFull 
*/
	use "${baseData}\servedBeneAnalyticFile.dta",clear
		sort bene_id clm_id
		capture drop _merge
		merge 1:1 bene_id clm_id using ${outData}\mSetFull
		
		*only need to keep beneficiaries that that have measure and index discharge characteristic data
		tab _merge served
		keep if _merge ==3
		drop _merge

/*
	for some reason, only beneficiaries from "continuing site" associated partner hospitals 
	should be counted so, this next merge and keep subsets appropriately to
	 (1) keep CCTP beneficiaries discharged from CCTP hospitals within the 59 continuing sites --> _merge ==3
	 (2) and non-cctp beneficiaries. NOTE:  comparison benes matched with those droped by keep if _merge ==3 
		will be removed later
*/
/*    --> REMOVED for the time being
		sort prvdr_num
		merge m:1 prvdr_num using ${baseData}\partnerHospital_fromContSites
		tab _merge served

		keep if _merge ==3 | served ==0
		tab served,mi

		drop _merge
*/

		

*initiate log
capture log close
log using "${logData}/Served_Bene_CS_Analysis_${date}", replace


foreach m of local mlist{
	
	*levelsof quarter, local(qtrs)
	local qtrs all //2012_1 2012_2 2012_3 2012_4 2013_1 2013_2 2013_3 2013_4 2014_1 2014_2 2014_3 2014_4 2015_1 


		
	* drop obs with missing AHA data
		drop if missing(bdtot, admtot, vem, voth, for_profit, percent_medicare, percent_medicaid, cmi)

	* loop through all quarters for cross-sectional regressions
	foreach q of local qtrs{
		preserve 
			egen qtr = group(quarter)
			
			* apply SAS coded measure-specific denominator exclusions and establish analysis variable name
			selectMeasure `m'
			
			* make sure the 1:1 match valid after measure specific exclusions
			evenSample

			*subset to applicable quarters 
			if "`q'" != "all" {
				keep if quarter == "`q'"
    			local qfix ""    // no quarter fixed effects when looking at individual qtr
			}
			else {
				*for quarter fixed effects when pooling all quarter periods
				local qfix "i.qtr"
			}
			
			disp "*************************************************************"
			disp "********** Served Bene Analysis for `m' Measure *************"
			disp "********* From PQ 1 (2012_1) through Quarter `q' ************"
			disp "*************************************************************"

			*quarter inclusion check
			tab quarter served
			
			*run LPM/OLS model
			reg ${dep} i.served `indepVar' `qfix', vce(cluster prvdr_num)
			
			disp "*************************************************************"
			disp "MARGINS COMMANDS"
			disp "*************************************************************"
			
								
			*A: if served ==0, at served= 0 represents effect of treating control as control
			*B: if served ==0, at served= 1 represents effect of treating treatment as control
			*C: if served ==1, at served= 0 represents effect of treating control as treatment
			*D; if served ==1, at served= 1 represents effect of treating treatment as treatment
			disp "Option A:"
			margins if served==0, at(served=(0 1))
			margins if served==1, at(served=(0 1))
			
			*Gives you A and D as outlined above, in that order (i.e. 0 as 0 and 1 as 1)			
			disp "Option B:"
			margins if served==0
			margins if served==1
			
			*Same as above, but in one table
			disp "Option C:"
			margins, over(served)
			
			*Gives you B and D as outlined in Option A, in that order (i.e. 0 as 1 and 1 as 0)
			
			disp "Option D:"
			margins i.served
			
			disp "Option E:"
			margins r.served
		
			*comment out after this point 
			
			}
			}
			
			/*
			
			*store select estimates from regression
			mat a = r(table)
			mat list a
			*get CCTP bene and nonCCTP bene sample sizes to meet QDM6 table requirements
			tab served if e(sample)
			
			
			count if served == 0 & e(sample)
			local numOfC `r(N)'

			count if served == 1 & e(sample)
			local numOfS `r(N)'
			
			
			local mFactor 1
			*set multiplicative factor for binary outcomes
			if inlist("`m'", "readmit", "obs","ed"){
				local mFactor 100
			}
			
			*create measure-specific data set that will ultimately go to excel tables
			local tq = qtr[1]
			
			gen cnt = 1
			
			*capture descriptive results
			if "`q'" == "all" {
				getQtrDesc `m' `q' `numOfS' `numOfC' `tq' `mFactor'
			}
			
			clear
				set obs 1
				gen id = 1				
				gen measure = "`m'"
				gen period = "`q'"
				gen tSample = "`numOfS'"
				gen cSample = "`numOfC'"
				
				local s = `numOfS' + `numOfC'
				gen totSample = "`s'"
				gen qNumber = "`tq'"
				destring qNumber, replace
				gen coeffSE   = string(a[1,1]*`mFactor', "%9.2fc")+ cond(a[4,1] < 0.01, "**", cond(a[4,1]<0.05,"*", cond(a[4,1]<0.1, "+", ""))) + " (" + string(a[2,1]*`mFactor', "%9.2fc")+")"
				gen coeff     = a[1,1]*`mFactor'
				gen se        = a[2,1]*`mFactor'
				
				save ${interimData}\tmp_`m'_`q' , replace
		restore
	}
}

/************************************************************************/
/******* IF measures are added then the if statements below will ********/
/******* also need to be updated */
/************************************************************************/


clear
/*CAPTURE REGRESSION RESULTS*/
*append all estimated measure data sets
local mFiles : dir "${interimData}" files "tmp_*"
local mlist  readmit obs ed ppay_total ppay_snf ppay_hha ppay_car ppay_inp ppay_out ppay_hsp ppay_dme

disp `mFiles'
foreach v of local mFiles{
	append using ${interimData}/`v'
 }

*translate REGRESSION results to MS Excel Tables
 cd ${outData}

global tableName "QDM6_ServedBeneAnalysis2"	//name of excel file

foreach m of local mlist{
	local s 3
		preserve
			keep if measure == "`m'"
			local len = _N
				putexcel C`s'=("Program Period") D`s'=("Treatment Sample Size") E`s'=("Comparison Sample Size") F`s'=("Total Sample Size") G`s'=("Coefficient Estimate (SE)")  using ${tableName}, sheet("`m'") modify 
				local s = `s'+1
			forval i = 1/`len'{
				putexcel C`s'=(period[`i']) D`s'=(tSample[`i']) E`s'=(cSample[`i']) F`s'=(totSample[`i']) G`s'=(coeffSE[`i'])  using ${tableName}, sheet("`m'") modify 
				local s = `s' + 1
			}
		restore
		
}

*create corresponding graphics
foreach m of local mlist{

	drop if period =="all"
	
	preserve 
	keep if measure =="`m'"
	if substr("`m'",1,4) != "ppay" local xLab "Percent"
	else local xLab "2012 Dollars"

  *** Plot
  serrbar coeff se qNumber, scale (1.96) yline (0) legend(order(2 1) ///
		label(1 "Confidence Interval") label(2 "Regression Estimate") on) ///
		ytitle("`xLab'") xscale(titlegap(2)) ///
		xlabel(	  1 `" "Q1" "(2/1/12 -" "4/30/12)" "' ///
				  2 `" "Q2" "(5/1/12 -" "7/31/12)" "' ///
				  3 `" "Q3" "(8/1/12 -" "10/31/12)" "' ///
				  4 `" "Q4" "(11/1/12 -" "1/31/13)" "' ///
				  5 `" "Q5" "(2/1/13 -" "4/30/13)" "' ///
				  6 `" "Q6" "(5/1/13 -" "7/31/13)" "' ///
				  7 `" "Q7" "(8/1/13 -" "10/31/13)" "' ///
				  8 `" "Q8" "(11/1/13 -" "1/31/14)" "' ///
				  9 `" "Q9" "(2/1/14 -" "4/30/14)" "' ///
				 10 `" "Q10" "(5/1/14 -" "7/31/14)" "' ///
				 11 `" "Q11" "(8/1/14 -" "10/31/14)" "' ///
				 12 `" "Q12" "(11/1/14 -" "1/31/15)" "' ///
				 13 `" "Q13" "(2/1/15 -" "4/30/15)" "', ///
				 labsize(2.1)) xtitle(CCTP Program Quarter, size(4))  
		
  *** Export
  graph export ${outData}/QDM6_served_estimates_`m'.tif, replace
   restore

}


/*CAPTURE DESCRIPTIVES*/
*append all estimated measure data sets
local mFiles : dir "${interimData}" files "tdesc_*"

clear
disp `mFiles'
foreach v of local mFiles{
	append using ${interimData}/`v'
 }
gen period = quarter
replace period = "all" if missing(period)
sort period
gen len = strlen(quarter)
capture drop qNumber
egen qNumber = group(quarter)
	
*translate DESCRIPTIVES  to MS Excel Tables
 cd ${outData}

foreach m of local mlist{
	local s 3
		preserve
			keep if measure == "`m'"
			local len = _N
				putexcel J`s'=("Program Period") K`s'=("Treatment Mean") L`s'=("Treatment Sample Size") M`s'=("Comparison Mean") N`s'=("Comparison Sample Size") O`s'=("Total Sample Size") P`s'=("Difference between Treatment and Comparison")  using ${tableName}, sheet("`m'") modify 
				local s = `s'+1
			forval i = 1/`len'{
				putexcel J`s'=(period[`i']) K`s'=(tMean[`i']) L`s'=(tSample[`i'])  M`s'=(cMean[`i']) N`s'=(cSample[`i'])  O`s'=(totSample[`i']) P`s'=(diff[`i'])  using ${tableName}, sheet("`m'") modify 
				local s = `s' + 1
			}
		restore
}

*create corresponding graphics
foreach m of local mlist{
	capture noisily destring tMean, ignore(",") replace
	capture noisily destring cMean, ignore(",") replace

	drop if missing(qNumber)	
	
	preserve 
		keep if measure =="`m'"

		if measure == "readmit"{
			local xLab "Readmission Rate(%)"
			local scle "0(5)25"
		}
		else if(measure == "ed"){
			local xLab "ED Visits Rate (%)"
			local scle "0(5)25"
		}
		else if(measure == "obs"){
			local xLab "Observation Services Use Rate (%)"
			local scle "0(1)5"
		}
		else if(substr(measure,1,4) == "ppay"){
			local xLab "Total Expenditures ($)"
			local scle "0(2000)9000"
		}
	
		twoway connected tMean cMean  qNumber, ytick(`scle') ylabel(`scle') legend(order(1 2) ///
		label(1 "CCTP Participants") label(2 "Matched Beneficaries") on) ///
		ytitle("`xLab'") xscale(titlegap(2)) ///
		xlabel(	  1 `" "Q1" "(2/1/12 -" "4/30/12)" "' ///
				  2 `" "Q2" "(5/1/12 -" "7/31/12)" "' ///
				  3 `" "Q3" "(8/1/12 -" "10/31/12)" "' ///
				  4 `" "Q4" "(11/1/12 -" "1/31/13)" "' ///
				  5 `" "Q5" "(2/1/13 -" "4/30/13)" "' ///
				  6 `" "Q6" "(5/1/13 -" "7/31/13)" "' ///
				  7 `" "Q7" "(8/1/13 -" "10/31/13)" "' ///
				  8 `" "Q8" "(11/1/13 -" "1/31/14)" "' ///
				  9 `" "Q9" "(2/1/14 -" "4/30/14)" "' ///
				 10 `" "Q10" "(5/1/14 -" "7/31/14)" "' ///
				 11 `" "Q11" "(8/1/14 -" "10/31/14)" "' ///
				 12 `" "Q12" "(11/1/14 -" "1/31/15)" "' ///
				 13 `" "Q13" "(2/1/15 -" "4/30/15)" "', ///
				 labsize(2.1)) xtitle(CCTP Program Quarter, size(4)) 
			
  *** Export
  graph export ${outData}/QDM6_served_unadjusted_`m'.tif, replace
	restore
	
}
