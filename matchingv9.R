#createdBy: David Ruiz
#lastModified: 20150112
#lastUpdate: use two different data sets for matching; ACC dataset comtains partial unit RAD-development information
#Description: 
#

install.packages("sas7bdat")
#install.packages("Matching", dependencies=TRUE)

#initiate sas7bdat library for reading in foreign file
library(sas7bdat)
library("Matching")
#library(gmodels)

#read in SAS DS with the read.sas7bsdat() function
#tempradDS = read.sas7bdat('~/Dropbox/Econometrica/RAD/match_10092014_acc.sas7bdat')


radDS = read.sas7bdat('~/Dropbox/Econometrica/RAD/match2_alt_02182015_acc.sas7bdat')

#validate input frame
is.data.frame(radDS)
summary(radDS$FLAG_RAD)

#quick test of FLAG_SAMPLE AND FLAG_RAD cross-tab; i'll use the native package in case i want to run some independece tests in the future.
xtabs(~ FLAG_RAD+FLAG_SAMPLE, data=radDS)

#get rid of the 254 unecessary rad projects
radDS <-radDS[ which(!(radDS$FLAG_SAMPLE==0 & radDS$FLAG_RAD==1)),]
xtabs(~ FLAG_RAD+FLAG_SAMPLE, data=radDS)


#init treatment dummy for the 6,044 (= potential controls + treatment) observations still left
radDS$FLAG_TRUE <- rep(0,5878)

#some arithmatic jiu jitsu to get a numeric binary for all 22 RADs vs all other developments
radDS$FLAG_TRUE <-  radDS$FLAG_RAD==1 & radDS$FLAG_SAMPLE==1
radDS$FLAG_TRUE <- radDS$FLAG_TRUE * 1
xtabs(~ FLAG_RAD+FLAG_SAMPLE, data=radDS)
#test flag
xtabs(~ FLAG_TRUE, data=radDS) #xtabs = cross tab table (usually stored as a DF) https://stat.ethz.ch/R-manual/R-devel/library/stats/html/xtabs.html



   
#yes, attach() can be dangerous but i will be super careful
names(radDS)
attach(radDS)

#
summary(radDS)


#sink(file='C:\\Users\\druiz\\Dropbox\\RAD\\acc.txt')
sink(file='~/Dropbox/Econometrica/RAD/rad_150221.txt')

#establish the weighing matrix with relevant variable columns
x <- cbind(radDS$ACC_UNIT_CNT, radDS$BLDG_TYPE_CODE,radDS$DEV_TYPE_CODE,radDS$DOFA,radDS$PERCENT_1_2_BED,radDS$PHA_SIZE_CODE,radDS$Rounded_Inspection_score,radDS$VACANCY_RATE,radDS$cost_burden_rate,radDS$overcrowd_rate,radDS$poverty_rate,radDS$renter_rate,radDS$vacant_rate )#deparse.level=2)

#establish balanceMatrix for the actual model
BalanceMatrix <- cbind(radDS$ACC_UNIT_CNT, radDS$BLDG_TYPE_CODE,radDS$DEV_TYPE_CODE,radDS$DOFA,radDS$PERCENT_1_2_BED,radDS$PHA_SIZE_CODE,radDS$Rounded_Inspection_score,radDS$VACANCY_RATE,radDS$cost_burden_rate,radDS$overcrowd_rate,radDS$poverty_rate,radDS$renter_rate,radDS$vacant_rate )#deparse.level=2)

#CHECK for missing values
any(is.na(radDS$FLAG_TRUE))
any(is.na(x))
any(is.na(BalanceMatrix))

gen1 <- GenMatch(Tr = radDS$FLAG_TRUE, X = x, BalanceMatrix = BalanceMatrix, M=4, pop.size = 7000, ties=TRUE, replace=FALSE)
#TR = vector for the treatment indicator = FLAG_TRUE for this DS 
#X = covariates that we will match on 
#balanceMatrix = the variables we want to achieve balance on

#running MATCH is not necessary since I do not care about causal inference; this matching is for site visits apparently 
#run the match WITHOUT an outcome that uses genMatch weighting matrix; kept all parameters - e.g., 4 controls per treatment, deterministic ties, no-replacement
mgen1 <- Match(Tr=radDS$FLAG_TRUE, X=x, M=4, replace=FALSE, ties=TRUE, Weight=3, Weight.matrix=gen1)
summary(mgen1)
mbgen1 <- MatchBalance(radDS$FLAG_TRUE~radDS$ACC_UNIT_CNT + radDS$BLDG_TYPE_CODE + radDS$DEV_TYPE_CODE + radDS$DOFA + radDS$PERCENT_1_2_BED + radDS$PHA_SIZE_CODE + radDS$Rounded_Inspection_score + radDS$VACANCY_RATE + radDS$cost_burden_rate + radDS$overcrowd_rate + radDS$poverty_rate + radDS$renter_rate + radDS$vacant_rate, data=radDS, match.out=mgen1, nboots=1000)

mlob1 <-Match(Tr=radDS$FLAG_TRUE, X=x, M=4, replace=FALSE, ties=TRUE, Weight=2)
summary(mlob1)
mblob1 <- MatchBalance(radDS$FLAG_TRUE~radDS$ACC_UNIT_CNT + radDS$BLDG_TYPE_CODE + radDS$DEV_TYPE_CODE + radDS$DOFA + radDS$PERCENT_1_2_BED + radDS$PHA_SIZE_CODE + radDS$Rounded_Inspection_score + radDS$VACANCY_RATE + radDS$cost_burden_rate + radDS$overcrowd_rate + radDS$poverty_rate + radDS$renter_rate + radDS$vacant_rate, data=radDS, match.out=mlob1, nboots=1000)


#redirect output back to console
sink()
#unlink('C:\\Users\\druiz\\Dropbox\\RAD\\rad.txt')

summary(gen1)

#SHOULD SEE: 24 treated, 96 matched
summary(mgen1)
summary(mlob1)





#now do some matrix magic to get a simple matrix showing the RAD propertie IDs and their 4 matched counterparts. 
dd = as.numeric(mgen1$index.control)
dim(dd) <- c(4,12)
dd <- t(dd)

dt = as.numeric(mgen1$index.treat)
dim(dt) <- c(4,12)
dt <- t(dt)
ds = cbind(dt[,1],dd)
df = matrix("",nrow=12,ncol=5)

df[,1] <- as.character(radDS$development_code[ds[,1]])
df[,2] <- as.character(radDS$development_code[ds[,2]])
df[,3] <- as.character(radDS$development_code[ds[,3]])
df[,4] <- as.character(radDS$development_code[ds[,4]])
df[,5] <- as.character(radDS$development_code[ds[,5]])

#write.matrix(df,'C:\\Users\\druiz\\Dropbox\\RAD\\match_acc.csv', sep=",")
#write.matrix(df,'C:\\Users\\druiz\\Dropbox\\RAD\\match_rad.csv', sep=",")
write.matrix(df,'~/Dropbox/Econometrica/RAD/match_rad_gen_150221.csv', sep=",")

############ mahanolobas

#now do some matrix magic to get a simple matrix showing the RAD propertie IDs and their 4 matched counterparts. 
dd = as.numeric(mlob1$index.control)
dim(dd) <- c(4,12)
dd <- t(dd)

dt = as.numeric(mlob1$index.treat)
dim(dt) <- c(4,12)
dt <- t(dt)
ds = cbind(dt[,1],dd)
df = matrix("",nrow=12,ncol=5)

df[,1] <- as.character(radDS$development_code[ds[,1]])
df[,2] <- as.character(radDS$development_code[ds[,2]])
df[,3] <- as.character(radDS$development_code[ds[,3]])
df[,4] <- as.character(radDS$development_code[ds[,4]])
df[,5] <- as.character(radDS$development_code[ds[,5]])

#write.matrix(df,'C:\\Users\\druiz\\Dropbox\\RAD\\match_acc.csv', sep=",")
#write.matrix(df,'C:\\Users\\druiz\\Dropbox\\RAD\\match_rad.csv', sep=",")
write.matrix(df,'~/Dropbox/Econometrica/RAD/match_rad_md_150221.csv', sep=",")

detach(radDS)


