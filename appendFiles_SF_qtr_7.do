set more off 
cd "S:\Shared\CHerlihy\data\SF_qtr_7"

global interim "S:\Shared\CHerlihy\data\SF_qtr_7"

//Measures to make plots for 
local mlist mort readmit30 icu los mpaypost30 mpayinp mpayinp_hp 

//Hospitals to make plots for 
local hlist "170183 310005 310006 310010 310012 310014 310015 310019 310024 310031 310032 310038 310044 310050 310051 310069 310070 310073 310081 310092 310096 310108 310110 310111 all"

local num 0
foreach v of local mlist{
	foreach z of local hlist{
	
	//Insert the right number into the file path (based on measure name) 
	if "`v'" == "mort" & "`z'" != "170183"{
		local num = 2
	}
	else if "`v'" == "mort" & "`z'" == "170183"{
		continue
	}
	
	else if "`v'" == "readmit30"{
		local num = 7
	}
	else if "`v'" == "icu" & "`z'" != "170183"{
		local num = 14
	}
	
	else if "`v'" == "icu" & "`z'" == "170183"{
		continue
	}
	else if "`v'" == "los"{
		local num = 15
	}
	else if "`v'" == "mpaypost30"{
		local num = 18
	}
	else if "`v'" == "mpayinp" | "`v'" ==  "mpayinp_hp" | "`v'" == "mpayinp_hp_std" |"`v'" ==  "mpayinp_nhp" {
		local num = 22
	}
	
	use ${interim}/ua_qtr_`num'_`v'_`z'.dta, clear 
	
	gen ms = "`v'"
	gen prvdr_num = "`z'"
	gen rate = `v'
	
	save ${interim}/OUT_ua_qtr_`v'_`z', replace
	}
}

//Append all "OUT" dta files into a single dta file for export to R
local mFiles : dir "${interim}" files "OUT_ua_qtr_*"

clear
	
	foreach z of local mFiles{
	
		append using ${interim}/`z'
	}

//This is the finished output file 
save ${interim}/SF_qtr_7_ALL , replace

outfile using ${interim}/SF_qtr_7_ALL.csv, comma
	
