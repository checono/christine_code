
use "S:\Shared\CHerlihy\bpci_phys_particip\datasets_out_v2\bpci_particip_rule24.dta", clear

* Get xTab of Physicians by Hospital-Quarter
tab hospitalid pq

* Standardize Variable Names
rename npinumber at_physn_npi
rename hospitalid prvdr_num

*** Assign BPCI Quarters to each observation
gen 	qtr = 10 if pq == "PQ1"
replace qtr = 11 if pq == "PQ2"
replace qtr = 12 if pq == "PQ3"
replace qtr = 13 if pq == "PQ4"
replace qtr = 14 if pq == "PQ5"
replace qtr = 15 if pq == "PQ6"

*** Check the PQ indicator
gen pqnum = substr(pq,-1,.)
destring pqnum, replace
tab pqnum qtr

// Indicator variable and "pq" match. Keep variables needed only.
keep prvdr_num qtr

*** Convert prvdr_num to string to match the other files
tostring prvdr_num, replace

*** Get Count of Physicians Per Hospital For Numerator
gen HPhysNumer = 1
collapse (sum) HPhysNumer, by(prvdr_num qtr)
tab prvdr_num qtr

*** Set Withdrawn Exciting Hospitals to 0
replace HPhysNumer = 0 if prvdr_num == "310012" &  qtr == 14
replace HPhysNumer = 0 if prvdr_num == "310014" & (qtr == 13 | qtr == 14)
replace HPhysNumer = 0 if prvdr_num == "310015" &  qtr == 14
replace HPhysNumer = 0 if prvdr_num == "310051" &  qtr == 14
replace HPhysNumer = 0 if prvdr_num == "310073" & (qtr == 13 | qtr == 14)
replace HPhysNumer = 0 if prvdr_num == "310108" &  qtr == 14
replace HPhysNumer = 0 if prvdr_num == "310111" & (qtr == 13 | qtr == 14)

*ssssssssssssssssssssssssssssssss
save "S:\Shared\CHerlihy\bpci_phys_particip\CH_phys_particip_QA\CH_check_ImpaqCode_part1" , replace
*ssssssssssssssssssssssssssssssss


********************************************************************************
*** Generate Denominator File
********************************************************************************
global fileAnalysis "S:\Shared\AShangraw\data\2015_10\compressed\DID_2015_10_MSR22_SPLIT.dta"

use ${fileAnalysis}, clear

*** Keep variables needed only
keep prvdr_num at_physn_npi qtr treat_post H*

*** Remove observations before BPCI start (Q10) and limit to only first 5 quarters
keep if qtr >= 10 & qtr <= 14

*** Remove comparison hospitals
keep if HBPCI == 1

*** Keep only unique observations at the Provider, Physician, and Quarter level
duplicates drop qtr prvdr_num at_physn_npi, force

*** Get Count of Physicians Per Hospital For Denominator
gen HPhysDenom = 1
collapse (sum) HPhysDenom, by(qtr prvdr_num)

*** Get xTabs

table prvdr_num qtr, contents(mean HPhysDenom)

save "S:\Shared\CHerlihy\bpci_phys_particip\CH_phys_particip_QA\CH_check_ImpactCode_part2", replace
