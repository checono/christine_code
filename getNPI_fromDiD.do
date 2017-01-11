// Load data
use "S:\Shared\AShangraw\data\2015_10\compressed\DID_2015_10_MSR22_SPLITv4.dta", clear

adopath ++ "S:\Shared\CHerlihy\ado"

// Keep only active hopsitals 
drop if HBPCI == 0

// Check to make sure only BPCI hospitals are included
tab hpid
sort at_physn_npi qtr

preserve

distinct at_physn_npi

*Generate a variable for whether a single NPI is the attending or (?) operating phys @ multiple hospitals
by at_physn_npi qtr, sort: gen distinctNPI = _n == 1
keep if distinctNPI == 1
collapse (count) distinctNPI, by(at_physn_npi)

//by at_physn_npi qtr, sort: gen distinctNPI = _n == 1


outsheet at_physn_npi using "S:\Shared\CHerlihy\ITT\check1.csv" , replace

restore
 
