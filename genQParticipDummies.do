* This do-file takes the BPCI physician participation dta file as input,
* and creates quarterly dummies for each NPI number, to indicate whether or not
* each doctor (identified by NPI number) is participating in BPIC for a given
* hospital, calendar year quarter, and BPCI program quarter
*
* @Author: Christine Herlihy
* Last updated: 02/23/16
*
* Rules used to determine participation w/respect to sign up & exit dates:
* SIGN UP DATE:
*	(1) If sign up occurred DURING quarter in question, 
*		BPCI membership for this quarter = 0; the NEXT quarter gets a 1
*	(2) If sign up occurred DURING quarter in question, 
*		BPCI membership for this quarter = 1	
* EXIT DATE:
*	(3) If exit occurred DURING quarter in question, 
*		BPCI membership for this quarter = 0
*	(4) If exit occurred DURING quarter in question, 
*		BPCI membership for this quarter = 1; the NEXT quarter gets a 0	
log close
set more off
log using "S:\Shared\CHerlihy\bpci_phys_particip/genQParticipDummies_LOG_v2.smcl", replace
global outputDir "S:\Shared\CHerlihy\bpci_phys_particip/datasets_out_v2/"

import delimited using "S:\Shared\CHerlihy\bpci_phys_particip\CH_CMS_outputData_v2.csv", clear
drop v1

// use "S:\Shared\CHerlihy\bpci_phys_particip\bpci_participation_by_q_20060222.dta" // FOR ORIGINAL IMPORT OF AMS data provided by Alex
preserve	
		
*Generate a program quarter variable that corresponds to each "quarter" value
/*
gen pq = ""

replace pq = "PQ1" if quarter == 19449	//01apr2013
replace pq = "PQ2" if quarter == 19540	//01jul2013
replace pq = "PQ3" if quarter == 19632	//01oct2013
replace pq = "PQ4" if quarter == 19724	//01jan2014
replace pq = "PQ5" if quarter == 19814	//01apr2014

tab pq
*/

*Generate binary phys. particp. variable (by NPI, hospital, quarter)
gen BPCI = 0 

local toFormat signedupdate calcdeactivate programquarter

*Each date value in the input set is a date-time object in format %d; want to format as %td and %tq
foreach x of local toFormat{

	gen `x'_v1 = date(`x', "MD20Y")

	format `x'_v1 %td
	gen `x'_v2 = qofd(`x'_v1) //generate a new quarterly variable based on calendar date of each var
	format `x'_v2 %tq //put this in the format yyyyq# 
	
}

save "S:\Shared\CHerlihy\bpci_phys_particip\bpci_participation_by_q_TEMP_v2.dta", replace
restore 

*Loop through decision rules to generate 4 dta files 
local rules "rule13 rule14 rule23 rule24"
foreach x of local rules{
	
	use "S:\Shared\CHerlihy\bpci_phys_particip\bpci_participation_by_q_TEMP_v2.dta", clear
	preserve
	
	*RULE 13: If sign up occured DURING quarter, BPCI ==0; if exit occured DURING quarter, BPCI==0
	if("`x'" == "rule13"){

		disp "RULE 13: If sign up occured DURING quarter, BPCI ==0; if exit occured DURING quarter, BPCI==0" 
		replace BPCI = 1 if signedupdate_v2 < programquarter_v2 & programquarter_v2 < calcdeactivate_v2
		
		*Check logic
		tab BPCI
		list if BPCI == 0
		save ${outputDir}/bpci_particip_`x',replace	
	}
	
	
	*RULE 14: If sign up occured DURING quarter, BPCI ==0; if exit occured DURING quarter, BPCI==1
	else if("`x'" == "rule14"){
	
		disp "RULE 14: If sign up occured DURING quarter, BPCI ==0; if exit occured DURING quarter, BPCI==1"
		replace BPCI = 1 if signedupdate_v2 < programquarter_v2 & programquarter_v2 <= calcdeactivate_v2
	
		*Check logic
		tab BPCI
		list if BPCI == 0
		save ${outputDir}/bpci_particip_`x',replace	
	}
	
	
	*RULE 23: If sign up occured DURING quarter, BPCI ==1; if exit occured DURING quarter, BPCI==0
	else if("`x'" == "rule23"){
	
		disp "RULE 23: If sign up occured DURING quarter, BPCI ==1; if exit occured DURING quarter, BPCI==0"
		replace BPCI = 1 if signedupdate_v2 <= programquarter_v2 & programquarter_v2 < calcdeactivate_v2
	
		*Check logic
		tab BPCI
		list if BPCI == 0
		save ${outputDir}/bpci_particip_`x',replace	
	}
	
	
	*RULE 24: If sign up occured DURING quarter, BPCI ==1; if exit occured DURING quarter, BPCI==1
	else if("`x'" == "rule24"){
	
		disp "RULE 24: If sign up occured DURING quarter, BPCI ==1; if exit occured DURING quarter, BPCI==1"
		replace BPCI = 1 if signedupdate_v2 <= programquarter_v2 & programquarter_v2 <= calcdeactivate_v2
		
		*Check logic
		tab BPCI
		list if BPCI == 0

		save ${outputDir}/bpci_particip_`x',replace	
	}
	
	restore
}


