#Matching package demo (from Sekhon 2011)
library("Matching")
data("lalonde")
attach(lalonde)

#Save the outcome of interest in Y and the treatment indicator in Tr
Y<-lalonde$re78
Tr <- lalonde$treat 

#Estimate our first propensity score model:
glm1 <- glm(Tr~age + educ + black + hisp + married + nodegr + re74 + re75, family = binomial, data = lalonde)

#Do one-to-one matching w/replacement using our preliminary propensity score model where the estimand is the avg treatment effect on the treated (ATT):
X = glm1$fitted
rr1 <- Match(Y= Y, Tr = Tr, X = X)

#in rr1, Y is a vector containing the outcome variable, Tr is a vector containing the treatment status of each observation (i.e. either a zero or a one), 
# and X is a matrix containing the variables to be matched on, which in this case is simply the propensity score (so it should be a n * 1 matrix ? )

#None of these commands produce output; if you want to results from call to Match; do:
summary(rr1)

#The ratio of treated to control observations is det. by the M option, and the default is set to 1.
#whether 2 potential matches are close enough to be considered tied = det  by the distance.tolerance option; ties=handled determenistically by default

m1 = Match(Y=Y, Tr=Tr, X = glm1$fitted, estimand = "ATT", M=1, ties = TRUE, replace = TRUE)

#Generally, you want to measure balance for more functions of the data than  you include in your propesity score model
#Can do this by using the following call to MatchBalance function--it is asked to measure balance for many more funcs of the confounders than we incl in propensity score model:
MatchBalance(Tr~age + I(age^2) + educ + I(educ^2) + black + hisp + married + nodegr + re74 + I(re74^2) + re75 + I(re75^2) + u74 + u75 + I(re74*re75) + I(age*nodegr) + I(educ*re74) + I(educ *re75),
             match.out = rr1, nboots = 1000, data = lalonde)

#in R, I(var) signifies interaction term (??)

#Generally, one should request balance statistics on more higher-order terms and interactions than were included in the propensity score used to conduct the matching itself.

#see stats only for no degree (V8); results indicate that nodegr is poorly balanced before AND after matching; the diff b/w contorl and treatment is stat sig.
MatchBalance(Tr~ nodegr, match.out = rr1, nboots = 1000, data = lalonde)

#see results only for re74, which = real earnings of participants in 1974; the results = that the balance of re74 has been made WORSE by matching 
MatchBalance(Tr ~ re74, match.out = rr1, nboots = 1000, data = lalonde)

X<- cbind(age, educ, black, hisp, married, nodegr, re74, re75, u74, u75)
X


#to obtain balance statistics, do as follows w/the output object (gen1) returned by teh call to GenMatch above:
mgen1 <- Match(Y=Y, Tr = Tr, X=X, Weight.matrix = gen1)
BalanceMatrix <- cbind(age, I(age^2), educ, I(educ^2), black, hisp, married, nodegr, re74, I(re74^2), re75, I(re75^2), u74, u75,
                       I(re74*re75), I(age*nodegr), I(educ *re74), I(educ*re75))
#install.packages("rgenoud")
gen1 <-GenMatch(Tr = Tr, X= X, BalanceMatrix = BalanceMatrix, pop.size = 1000)
mgen1 <- Match(Y=Y, Tr = Tr, X=X, Weight.matrix = gen1)
MatchBalance(Tr~ age + I(age^2) + educ + I(educ^2) + black + hisp + married + nodegr + re74 + I(re74^2) + re75 + I(re75^2)
             + u74 + u75 + I(re74 * re75) + I(age*nodegr) + I(educ*re74) + I(educ *re75), data = lalonde, match.out = mgen1, nboots =1000)

#examine our estimate of the treatment effect and its standard error:
summary(mgen1)






##unrelated examples of using cbind

m <- cbind(1, 1:7) # the '1' (= shorter vector) is recycled
m
m <- cbind(m, 8:14)[, c(1, 3, 2)] # insert a column
m
cbind(1:7, diag(3)) # vector is subset -> warning

cbind(0, rbind(1, 1:3))
cbind(I = 0, X = rbind(a = 1, b = 1:3))  # use some names
xx <- data.frame(I = rep(0,2))
cbind(xx, X = rbind(a = 1, b = 1:3))   # named differently

cbind(0, matrix(1, nrow = 0, ncol = 4)) #> Warning (making sense)
dim(cbind(0, matrix(1, nrow = 2, ncol = 0))) #-> 2 x 1

## deparse.level
dd <- 10
rbind(1:4, c = 2, "a++" = 10, dd, deparse.level = 0) # middle 2 rownames
rbind(1:4, c = 2, "a++" = 10, dd, deparse.level = 1) # 3 rownames (default)
rbind(1:4, c = 2, "a++" = 10, dd, deparse.level = 2) # 4 rownames

## cheap row names:
b0 <- gl(3,4, labels=letters[1:3])
bf <- setNames(b0, paste0("o", seq_along(b0)))
df  <- data.frame(a = 1, B = b0, f = gl(4,3))
df. <- data.frame(a = 1, B = bf, f = gl(4,3))
new <- data.frame(a = 8, B ="B", f = "1")
(df1  <- rbind(df , new))
(df.1 <- rbind(df., new))
stopifnot(identical(df1, rbind(df,  new, make.row.names=FALSE)),
          identical(df1, rbind(df., new, make.row.names=FALSE)))


demo(DehejiaWahba)





