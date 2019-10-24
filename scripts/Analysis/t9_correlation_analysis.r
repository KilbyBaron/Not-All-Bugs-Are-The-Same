
#install.packages(c("dplyr","scales","relaimpo","rms","e1071","Hmisc"))
#install.packages("rms")
#install.packages("mvtnorm")
library(dplyr)
library(scales)
require(relaimpo)
library(rms)
library(e1071)
library(Hmisc)

#Read in CSV
df <- read.csv("/home/kjbaron/Documents/NABATS/intermediate_files/final_dataset.csv", header = TRUE)




################################################################################
# (MC -2) Normality adjustment
################################################################################
# Normalize indep. & dep. variables with min-max
df[c("exp","bfs","num_bugs","priority")] <- lapply(df[c("exp","bfs","num_bugs","priority")], function(x) c(scale(x, center= min(x), scale=diff(range(x))))) 

#Set independent variable names
ind_vars = c("bfs","exp","priority")

################################################################################
# (MC -3) Correlation analysis
################################################################################
#Calculate spearman's correlation between independent variables
vc <- varclus(~ ., data=df[,ind_vars], trans="abs")

#Plot hierarchical clusters and the spearman's correlation threshold of 0.7
plot(vc)
threshold <- 0.7
abline(h=1-threshold, col = "red", lty = 2)


################################################################################
# (MC -5) Fit regression model
################################################################################
#Create a matrix to fill with R^2 values
t9_results <- matrix(ncol=10, nrow=13)
t9_results[1,] <- c("Project", "Y bfs","","","exp","","","priority","","")
t9_results[2,] <- c("","R1","R2","R3","R1","R2","R3","R1","R2","R3")
i <- 3

num_iter = 1000
#RMS package requires a data distribution when building a model
for (current_project in c("accumulo","bookkeeper","camel","cassandra","cxf","derby","felix","hive","openjpa","pig","wicket"))
{

  #Extract project
  p_df <- filter(df, project == current_project)
  
  #Add project name to row
  t9_results[i,1] <- current_project
  
  releases <- unique(p_df[c("minor")])
  j<-1
  for (r in releases[["minor"]]){
    
    r_df <- filter(p_df, minor == r)
    r_df[c("exp","bfs","num_bugs","priority")] <- lapply(r_df[c("exp","bfs","num_bugs","priority")], function(x) c(scale(x, center= min(x), scale=diff(range(x)))))
    
    dd_numbugs <- datadist(r_df[,c("num_bugs",ind_vars)])
    options(datadist = "dd_numbugs")
    fit_numbugs <- lm(num_bugs ~ bfs+exp+priority, data=r_df, x=T, y=T)
    r2_numbugs <- calc.relimp(fit_numbugs, type="lmg", rela=FALSE)@R2
    lmg_numbugs <- calc.relimp(fit_numbugs, type="lmg", rela=TRUE)@lmg
    
    bfs_corr <- lmg_numbugs['bfs']*r2_numbugs
    exp_corr <- lmg_numbugs['exp']*r2_numbugs
    pri_corr <- lmg_numbugs['priority']*r2_numbugs
    
    t9_results[i,1+j] <- bfs_corr
    t9_results[i,4+j] <- exp_corr
    t9_results[i,7+j] <- pri_corr
    
    j<-j+1

  }
  i <- i+1
}


write.csv(t9_results, file = "/home/kjbaron/Documents/NABATS/intermediate_files/t9.csv",row.names=FALSE,na="")

