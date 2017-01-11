clear all
set more off
cap log close
set logtype text
global Path "S:\Shared\CHerlihy\results"
cd ${Path}


use "S:\Shared\CHerlihy\results\table1_bpci.dta" 
preserve


levelsof outcome, local(outcomes)
levelsof bpci_treat_post, local(treat_post)
levelsof bpci_treat_base, local(treat_base)
levelsof bpci_cont_post, local(cont_post)
levelsof bpci_cont_post, local(cont_base)
local allVars 
local didOut 


foreach a of local outcomes{
	foreach b of local treat_post{
		foreach c of local treat_base{
			foreach d of local cont_post{
				foreach e of local cont_base{
						* local didOut =((`b'/`d')/(`c'/`e'))
						 local temp = ((`b'/`d')/(`c'/`e'))
						 local didOut `didOut' `temp'
						 
				}
			}
		}
	}
}


foreach x of local didOut{
	
	display `x'
}
