
install.packages(c("dplyr","scales","relaimpo","rms","e1071","Hmisc"))
#install.packages("rms")
#install.packages("mvtnorm")
library(dplyr)
library(scales)
require(relaimpo)
library(rms)
library(e1071)
library(Hmisc)

#Read in CSV
df_harold <- read.csv("/home/kjbaron/Documents/NABATS/HAROLD/project-misclassified-files/experiments-fn-files/dataset-all-projects.csv", header = TRUE)
#df_harold <- filter(df_harold, num_post > 0)
#df_harold <- na.omit(df_harold) #remove rows with na values

#df_harold <- filter(df_harold, num_post > 0)

################################################################################
# (MC-1) Estimate budget for degrees of freedom
################################################################################
#Since we plan to fit using ordinary least squares, we use the below rule of
# thumb to estimate our budget
print( floor(min(nrow(df_harold[df_harold$exp > 0,]), nrow(df_harold[df_harold$exp == 0,]) )/15))
print(floor(min(nrow(df_harold[df_harold$bfs > 0,]), nrow(df_harold[df_harold$bfs == 0,]) )/15))
print(floor(min(nrow(df_harold[df_harold$num_bugs > 0,]), nrow(df_harold[df_harold$num_bugs == 0,]) )/15))

################################################################################
# (MC -2) Normality adjustment
################################################################################
# Normalize indep. & dep. variables with min-max
df_harold[c("lines","cyclomatic","churn","mean_experience","changed_lines","num_issues")] <- lapply(df_harold[c("lines","cyclomatic","churn","mean_experience","changed_lines","num_issues")], function(x) c(scale(x, center= min(x), scale=diff(range(x))))) 

#Set independent variable names
ind_vars = c("lines","cyclomatic","churn")

################################################################################
# (MC -3) Correlation analysis
################################################################################
#Calculate spearman's correlation between independent variables
vc <- varclus(~ ., data=df_harold[,ind_vars], trans="abs")

#Plot hierarchical clusters and the spearman's correlation threshold of 0.7
plot(vc)
threshold <- 0.7
abline(h=1-threshold, col = "red", lty = 2)

################################################################################
# (MC -4) Redundancy analysis
################################################################################
red <- redun(~ ., data=df_harold[,ind_vars], nk=0)
print(red)

sp <- spearman2(formula(paste("num_issues" ," ~ ",paste0(ind_vars, collapse=" + "))), data= df_harold, p=2)
plot(sp)
print(sp)


################################################################################
# (MC -5) Fit regression model
################################################################################
#Create a matrix to fill with R^2 values
r2_results <- matrix(ncol=4, nrow=12)
r2_results[1,] <- c("Project", "Y #Bugs", "Y ChgLines", "Y Exp")
i <- 2

num_iter = 1000
#RMS package requires a data distribution when building a model
for (current_project in c("accumulo","bookkeeper","camel","cassandra","cxf","derby","felix","hive","openjpa","pig","wicket"))
{
  print(current_project)
  
  #Extract project
  p_df <- filter(df_harold, project == current_project)
  p_df[c("lines","cyclomatic","churn","mean_experience","changed_lines","num_issues")] <- lapply(p_df[c("lines","cyclomatic","churn","mean_experience","changed_lines","num_issues")], function(x) c(scale(x, center= min(x), scale=diff(range(x))))) 
  
  #RMS package requires a data distribution when building a model
  print(dim(p_df[,c("mean_experience",ind_vars)]))
  dd_exp <- datadist(p_df[,c("mean_experience",ind_vars)])
  options(datadist = "dd_exp")
  
  dd_bfs <- datadist(p_df[,c("changed_lines",ind_vars)])
  options(datadist = "dd_bfs")
  
  dd_bugs <- datadist(p_df[,c("num_issues",ind_vars)])
  options(datadist = "dd_bugs")
  
  #Build generalized linear models for each dependent variable
  fit_exp <- lm(mean_experience ~ lines+cyclomatic+churn, data=p_df, x=T, y=T)
  #print(summary(fit_exp))
  fit_bfs <- lm(changed_lines ~ lines+cyclomatic+churn, data=p_df, x=T, y=T)
  #print(summary(fit_bfs))
  fit_bugs <- lm(num_issues ~ lines+cyclomatic+churn, data=p_df, x=T, y=T)
  #print(summary(fit_bugs))
  
  #Calculate R^2
  #lmg is the R^2 contribution averaged over orderings among regressors\
  # Metrics normalized to sum to 100% --> (rela=TRUE), otherwise --> (rela=FALSE)
  r2_exp <- calc.relimp(fit_exp, type="lmg", rela=FALSE)@R2
  r2_bfs <- calc.relimp(fit_bfs, type="lmg", rela=FALSE)@R2
  r2_bugs <- calc.relimp(fit_bugs, type="lmg", rela=FALSE)@R2
  
  #Add results to maxtrix
  r2_results[i,] <- c(current_project, r2_bugs, r2_bfs, r2_exp)
  i <- i+1
}


#  The code below is most the same as for Table 5, but rela=TRUE in the relimp calculation 
#  -- just separated the code by table to keep it easy to read
#  --------------------------------------------------------------------------------------------------------------------------
#  TABLE 6 - Average contributions from each independent variable when different dependent variables are used
#  --------------------------------------------------------------------------------------------------------------------------


#Create a matrix to fill with values
t6_results <- matrix(ncol=5, nrow=34)
t6_results[1,] <- c("Project", "Features", "Y #Bugs", "Y ChgLines", "Y Exp")
i <- 2

#Calculate contributions for each dependent variable of each project
for (current_project in c("accumulo","bookkeeper","camel","cassandra","cxf","derby","felix","hive","openjpa","pig","wicket"))
{
  
  #Extract project data and standardize indep. & dep. variables
  p_df <- filter(df, project == current_project)
  p_df[c("lines","cyclomatic","churn","mean_experience","changed_lines","num_issues")] <- lapply(p_df[c("lines","cyclomatic","churn","mean_experience","changed_lines","num_issues")], function(x) c(scale(x, center= min(x), scale=diff(range(x))))) 
  
  #Build generalized linear models for each dependent variable
  m_exp <- lm(mean_experience ~ lines+cyclomatic+rcs(churn,3), data=p_df, x=T, y=T)
  m_bfs <- lm(changed_lines ~  lines+cyclomatic+rcs(churn,3), data=p_df, x=T, y=T)
  m_bugs <- lm(num_issues ~ lines+cyclomatic+rcs(churn,3), data=p_df, x=T, y=T)
  
  #Calculate R^2
  #lmg is the R^2 contribution averaged over orderings among regressors
  lmg_exp <- calc.relimp(m_exp, type="lmg", rela=TRUE)@lmg
  lmg_bfs <- calc.relimp(m_bfs, type="lmg", rela=TRUE)@lmg
  lmg_bugs <- calc.relimp(m_bugs, type="lmg", rela=TRUE)@lmg
  
  
  #Add results to maxtrix
  t6_results[i,] <- c(current_project, "X LOC", lmg_bugs['lines'], lmg_bfs['lines'], lmg_exp['lines'])
  t6_results[i+1,] <- c(current_project, "X CC", lmg_bugs['cyclomatic'], lmg_bfs['cyclomatic'], lmg_exp['cyclomatic'])
  t6_results[i+2,] <- c(current_project, "X churn", lmg_bugs['rcs(churn, 3).churn'], lmg_bfs['rcs(churn, 3).churn'], lmg_exp['rcs(churn, 3).churn'])
  i <- i+3
}


