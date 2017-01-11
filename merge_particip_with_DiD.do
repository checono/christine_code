// Do-file to merge the BPCI physician participation CMS data with DiD dataset by NPI, quarter, hospital 

use "S:\Shared\CHerlihy\bpci_phys_particip\datasets_out_v2\bpci_particip_rule24.dta", clear

tostring npinumber hospitalid, replace

gen quarterMerge = ""
replace quarterMerge = "2013-2" if pq == "PQ1"
replace quarterMerge = "2013-3" if pq == "PQ2"
replace quarterMerge = "2013-4" if pq == "PQ3"
replace quarterMerge = "2014-1" if pq == "PQ4"
replace quarterMerge = "2014-2" if pq == "PQ5"

// rename npinumber at_physn_npi
rename npinumber at_physn_npi
rename hospitalid prvdr_num
rename quarterMerge quarter

sort prvdr_num  at_physn_npi quarter quarter

save "S:\Shared\CHerlihy\bpci_phys_particip\forMergeWithDiD.dta", replace
use "S:\Shared\AShangraw\data\2015_10\compressed\Did_2015_10_msr14.dta", clear
sort prvdr_num  at_physn_npi quarter quarter

format quarter %9s

merge m:1 at_physn_npi prvdr_num quarter using "S:\Shared\CHerlihy\bpci_phys_particip\forMergeWithDiD.dta"
unique(at_physn_npi) if _merge ==2

/* If we match on at_physn_npi:

. unique(at_physn_npi) if _merge ==2
Number of unique values of at_physn_npi is  1005
Number of records is  3409
*/

// ****************************************************************************/

/* IF we match on op_physn_npi:

    Result                           # of obs.
    -----------------------------------------
    not matched                     2,190,260
        from master                 2,186,440  (_merge==1)
        from using                      3,820  (_merge==2)

    matched                            39,327  (_merge==3)
    -----------------------------------------

. unique(op_physn_npi) if _merge ==2
Number of unique values of op_physn_npi is  1169
Number of records is  3820

*/

// ****************************************************************************/
/*
 IF we match on ot_physn_npi

  Result                           # of obs.
    -----------------------------------------
    not matched                     2,235,604
        from master                 2,225,763  (_merge==1)
        from using                      9,841  (_merge==2)

    matched                                 4  (_merge==3)
    -----------------------------------------

. unique(ot_physn_npi) if _merge ==2
Number of unique values of ot_physn_npi is  2020
Number of records is  9841

*/




*keep if _merge == 3


save "S:\Shared\CHerlihy\bpci_phys_particip\merged_particip_DiD_v2.dta"
