adopath + "S:\Shared\CHerlihy\ado"
log using "${Path}\logs\Charlson_test", replace
use "S:\Shared\CHerlihy\data\2015_10\PSM_2012_1.DTA" 
charlson icd_dgns_cd1-icd_dgns_cd25, index(e) assign0
