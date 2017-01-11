/*
EXAMPLES: https://www.ssc.wisc.edu/sscc/pubs/stata_psmatch.htm

*/

/*
*m: load sample data
use http://ssc.wisc.edu/sscc/pubs/files/psm, clear


gen z = _n
gen odd = mod(z,2)


probit t x1 x2

predict p, pr 


sum p




*m: run psm matching with NN(1) & replacement
teffects nnmatch  (p) (t) //, nn(1) gen(match) //ematch(odd)


*teffects psmatch (y) (t x1 x2,probit), nn(1) gen(match)

gen ob=_n

save fullSample, replace 


                keep if t
                keep match1
                bys match1: gen weight = _N
                by match1: keep if _n==1
                rename match1 ob

merge 1:m ob using fullSample
replace weight = 1 if t

/*shows number of treated (t==1) and matched non-treated (t==0)*/
tab t if !missing(weight)
*/



/*psm duplication*/

****************************************************************************************************
/*probable s0lution*/
****************************************************************************************************
use "S:\Shared\CHerlihy\data\2015_10\PSM_2012_1.DTA", clear 

*ORIGINAL: local matchingChar  dual snf_disch hrrnum age male black hisp oth_dk wcharlsum admissions readmissions los ed_visits admissions_zero readmissions_zero los_zero ed_visits_zero round* pay*pre1_zero pay*pre26_zero imp_hcc_4cctp cc* ami hf pnu copd bdtot admtot vem voth for_profit percent_medicare percent_medicaid cmi  cbsa_division cbsa_metro 


local matchingChar  dual_qtr snf_disch hrrnum age male black hisp oth_dk charlindex admissions readmissions los ed_visits admissions_zero readmissions_zero los_zero ed_visits_zero round* pay*pre1_zero pay*pre26_zero imp_hcc_4cctp cc* ami hf pnu copd bdtot admtot vem voth for_profit percent_medicare percent_medicaid cmi  cbsa_division cbsa_metro 

//For ed_visits and ed_visits_zero , we need to decide if we want op, ip, or both (for each)
//round* doesn't seem to align with any var in the dataset  



*ORIGINAL egen exactMatch = group(hrrnum dual quarter snf_stay)
egen exactMatch = group(hrrnum dual snf_stay)

local eMLevels = levelsof(exactMatch)
foreach z of local eMLevels{

                preserve
                                *m: subset data to exactMatch criteria
                                keep if exactMatch == `z'
                                
                                *m: compute pscore
                                probit served `matchingChar'
                                
                                                predict ps if e(sample), pr
                                
                                *m: set caliper for match
                                local caliper = 0.25 * r(sd)
                                
                                *m: NN(1) match w/o replacement, caliper requirement, and common support
                                psmatch2 served, pscore(ps) neighbor(1) caliper(`caliper') common noreplacement
                                
                                *m: standardized test stats
                                pstest `matchingChar', both
                                
                                *m: isolate served and matched counter parts
                                keep if _weight !=0 
                                                tab _weight _treated
                                                tab _support _treated
                                                
                                *m: keep only necessary information to merge back to measure datasets
                                *keep bene_id clm_id _weight _treated _support quarter hrrnum prvdr_num served
                                
                                save ${intirimDir}\matchedSubSet_`quarter', replace
                restore
}

*m: identify and append all quarter-dual 
local mFiles : dir "${intirimDir}" files "*dta"

clear 
foreach v of local mFiles{
                append using "${intirimDir}\`v'"
}

*m: should show even served non-served numbers by quarter
tab quarter served

*pstest `matchingChart', both





*m: load sample data
use http://ssc.wisc.edu/sscc/pubs/files/psm, clear

gen z = _n
gen odd = mod(z,2)

teffects psmatch (y) (t x1 x2,probit), nn(1) gen(match)






