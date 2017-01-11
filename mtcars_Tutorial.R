require(xlsx)
require(plyr)

# The dataset we will work with displays Johnson & Johnson quarterly earnings per share, from 1960 to 1980
test <- mtcars


# For the sake of demonstration, let's say we want to produce a very simple report for each quarter, where we plot EPS from 1960 to 1980

# Put the paramter you want to loop over into a list
quarters <- c("Qtr1", "Qtr2", "Qtr3",  "Qtr4")

<- quarters



# Loop through the var you want to iterate on
# Within render, you need to call the associated RMarkdown file by name.
# The output file should correspond to the name you want to call each file; if you don't differentiate, each run will overwrite previous contents.
# Output here is a .docx; html and pdf are also options. 

for(i in 1:length(quarters)){
     
     rmarkdown::render("//Econo-file1/users/Shares/ZJ5586B/R/JandJ_Tutorial.Rmd", params = list(quarter = quarters[i], data=test),
                       output_file =  paste(quarters[i], "_test_.docx", sep=''), 
                       output_dir = '//Econo-file1/users/Shares/ZJ5586B/R/JJTest')
}
