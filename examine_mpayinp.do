/*
	Created by: CH
	Last Updated: 03/30/2016
	Objective : 
				
				General method requirements:
				
				Measures assessed: 
				
	
	Input     : 
				  
	Output    : 
				
	
	Notes     : 
				
*/


*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
* set up data, log, and output folders and other static 
* elements like the data version 
*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
clear all 
set more off


*set current date 
global date    "160330"

*set run number
global runNum 6

*set data path
global baseData    "S:\Shared\CHerlihy\bpci_mpayinp_sandbox/"

*set output folder
global outData     "S:\Shared\CHerlihy\data/${dataVer}/output"

*set log folder
global logData     "S:\Shared\CHerlihy\bpci_mpayinp_sandbox\logs"

*set ado path 		
adopath + "S:\Shared\David Ruiz\ado"

********************************************************************************

log using "logData\${date}"

use "DID_2016_01_MSR22_SPLIT_CHcopy.dta"
rename analysis_variable_all mpayinp










log close


