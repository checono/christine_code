# Compare costs of journal subscriptions
install.packages("mosaic")
library("mosaic")
require(ggplot2)

### JSTOR ###
# Information on price/options from http://purchase.jstor.org/quotecart/products.php

jstor <- data.frame(read.csv("\\\\ECONO-FILE1/USERS/Shares/ZJ5586B/R/JSTOR_Prices.csv"))
jstor <- jstor[1:7]

jstorCorporate <- jstor[which(jstor$JSTOR.Collection=="Complete Current Scholarship Collection"),7]

# Specific / Individual collections; corporation rate
jstorBusEcon <- 1430.00 #Business & Economics Discipline Package
jstorMedHealth <- 996.00 #Medicine & Allied Health Discipline Package
jstorPoliSocio <- 1112.00 #Political Science & Sociology Discipline Package
jstorSciTechMath <- 1814.60 #Science, Technology & Mathematics Discipline Package

# JPASS plans are personal and must be purchased and used by individuals; they were designed with a single user in mind.

jPassYearly <- 199.00  # JPass collection; read full text of all articles; download 120 PDFS
jpassYearlyPer <-199.00/120 # cost per
jPassMonthly <- (19.50*12) # JPass collection; read full text of all articles; download 10 PDFS/month



### ScienceDirect ###

# If we say "Corporate; US; Less than 10000 FTEs are researchers (smallest category)"

# With ScienceDirect ArticleChoiceT 100 Pre-paid Transactions you purchase a bundle of 100 articles / 
# book chapters that gives you flexible access to non-subscribed content on ScienceDirect. 
# You can then select articles from Journals including Backfiles, or book chapters from Book Series, 
# Handbooks, eBooks and Reference Works. Customers receive a monthly overview of number of articles / 
# book chapters used. Access is instant on ScienceDirect, both in HTML and PDF formats; in addition, 
# purchased articles can be downloaded and stored locally for future use. Full functionality of 
# ScienceDirect is available to users, including all abstracts, full-text searching, CrossRef, linking and
# personalization.

sciDirectArticleChoice100 <- 2900.00 # per 100 articles


# $31.50 per article or chapter for most Elsevier content. 
# Select titles are priced between $19.95 and $41.95 (subject to change). 
scidirPerArticle <- 31.50 


# Cost dataframe
compare <- data.frame(Journal= c("jstorBusEcon", "jstorMedHealth", "jstorPoliSocio", "jstorSciTechMath", "jPassYearly", "sciDirectArticleChoice100"), Price = c(jstorBusEcon, jstorMedHealth, jstorPoliSocio, jstorSciTechMath, jPassYearly, sciDirectArticleChoice100))
costPlot <- ggplot(data=compare, aes(x=Journal, y= Price, group=factor(Journal)))+ 
     geom_line(group=factor(compare$Journal))
print(costPlot)

