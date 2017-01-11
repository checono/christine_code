/*
	The imported data came from SAS analysis.
*/


*set data version
global dataVer "2015_10"

*set output folder
global outData     "S:\Shared\CHerlihy\data/${dataVer}/output"


import delimited S:\Shared\CHerlihy\data\2015_10\initirm\qdm6_did_adjusted.csv, clear

local mlist ed obs ppay readmit
*create graphics
foreach m of local mlist{

	capture drop if period =="all"
	
	preserve 
	keep if measure =="`m'"
	if "`m'" != "ppay" local xLab "Percentage Points"
	else local xLab "2012 Dollars"

  *** Plot
  serrbar coeff se qnumber, scale (1.96) yline (0) legend(order(2 1) ///
		label(1 "Confidence Interval") label(2 "DiD Estimate") on) ///
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
  graph export ${outData}/QDM6_DiD_estimates_`m'.png, replace
   restore

}

/*
	Unadjusted trends
*/


import delimited S:\Shared\CHerlihy\data\2015_10\initirm\qdm6_did_unadjusted.csv, clear

local mlist ed obs ppay readmit
*create graphics
foreach m of local mlist{

//	drop if qnumber==0

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
		else if(measure == "ppay"){
			local xLab "Total Expenditures ($)"
			local scle "0(2000)9000"
		}
	
		twoway connected served_hosp_mean comparison_hosp_mean  qnumber, ytick(`scle') ylabel(`scle') legend(order(1 2) ///
		label(1 "CCTP Hospitals") label(2 "Matched Comparison Hospitals") on) ///
		ytitle("`xLab'") xscale(titlegap(2)) ///
		xlabel(	  0 `" "Baseline" "(2010)" "' ///
				  1 `" "Q1" "(2/1/12 -" "4/30/12)" "' ///
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
  graph export ${outData}/QDM6_Unadjusted_estimates_`m'.png, replace
	restore
	
}
