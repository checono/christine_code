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
		xlabel(	  1 `" "Q1" "(Feb 2012 -" "Apr 2012)" "' ///
				  2 `" "Q2" "(May 2012 -" "Jul 2012)" "' ///
				  3 `" "Q3" "(Aug 2012 -" "Oct 2012)" "' ///
				  4 `" "Q4" "(Nov 2012 -" "Jan 2013)" "' ///
				  5 `" "Q5" "(Feb 2013 -" "Apr 2013)" "' ///
				  6 `" "Q6" "(May 2013 -" "Jul 2013)" "' ///
				  7 `" "Q7" "(Aug 2013 -" "Oct 2013)" "' ///
				  8 `" "Q8" "(Nov 2013 -" "Jan 2014)" "' ///
				  9 `" "Q9" "(Feb 2014 -" "Apr 2014)" "' ///
				 10 `" "Q10" "(May 2014 -" "Jul 2014)" "' ///
				 11 `" "Q11" "(Aug 2014 -" "Oct 2014)" "' ///
				 12 `" "Q12" "(Nov 2014 -" "Jan 2015)" "' ///
				 13 `" "Q13" "(Feb 2015 -" "Apr 2015)" "', ///
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
		label(1 "Participating Hospitals") label(2 "Matched Internal Comparison Hospitals") on) ///
		ytitle("`xLab'") xscale(titlegap(2)) ///
		xlabel(	  0 `" "Baseline" "(2010)" "' ///
				  1 `" "Q1" "(Feb 2012 -" "Apr 2012)" "' ///
				  2 `" "Q2" "(May 2012 -" "Jul 2012)" "' ///
				  3 `" "Q3" "(Aug 2012 -" "Oct 2012)" "' ///
				  4 `" "Q4" "(Nov 2012 -" "Jan 2013)" "' ///
				  5 `" "Q5" "(Feb 2013 -" "Apr 2013)" "' ///
				  6 `" "Q6" "(May 2013 -" "Jul 2013)" "' ///
				  7 `" "Q7" "(Aug 2013 -" "Oct 2013)" "' ///
				  8 `" "Q8" "(Nov 2013 -" "Jan 2014)" "' ///
				  9 `" "Q9" "(Feb 2014 -" "Apr 2014)" "' ///
				 10 `" "Q10" "(May 2014 -" "Jul 2014)" "' ///
				 11 `" "Q11" "(Aug 2014 -" "Oct 2014)" "' ///
				 12 `" "Q12" "(Nov 2014 -" "Jan 2015)" "' ///
				 13 `" "Q13" "(Feb 2015 -" "Apr 2015)" "', ///
				 labsize(2.1)) xtitle(CCTP Program Quarter, size(4)) 
			
  *** Export
  graph export ${outData}/QDM6_Unadjusted_estimates_`m'.png, replace
	restore
	
}
