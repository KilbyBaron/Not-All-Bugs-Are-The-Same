#install.packages("dplyr")
#install.packages("relaimpo")
#install.packages("scales")

library(dplyr)
library(scales)
require(relaimpo)

#Read in CSV
df <- read.csv("/home/kjbaron/Documents/NABATS/intermediate_files/mcrfs_all.csv", header = TRUE)
#df <- filter(df, num_pre > 0)
#df <- filter(df, num_post > 0)



#df <- filter(df, BFS > 0)
#df <- na.omit(df) #remove rows with na values



# ------------------------------------------------------------------------------------------
#  Table 5
# -----------------------------------------------------------------------------------------



#Create a matrix to fill with R^2 values
r2_results <- matrix(ncol=4, nrow=12)
r2_results[1,] <- c("Project", "Y #Bugs", "Y ChgLines", "Y Exp")
i <- 2

#Calculate R^2 for each dependent variable of each project
for (current_project in c("accumulo","bookkeeper","camel","cassandra","cxf","derby","felix","hive","openjpa","pig","wicket"))
{
  
  #Extract project data and standardize indep. & dep. variables
  p_df <- filter(df, project == current_project)
  p_df[c("LOC","CC","churn","experience","BFS","num_bugs")] <- lapply(p_df[c("LOC","CC","churn","experience","BFS","num_bugs")], function(x) c(scale(x, center= min(x), scale=diff(range(x)))))
  
  #Build generalized linear models for each dependent variable
  m_exp <- glm(formula = experience ~ LOC+CC+churn, data=p_df)
  m_bfs <- glm(formula = BFS ~ LOC+CC+churn, data=p_df)
  m_bugs <- glm(formula = num_bugs ~ LOC+CC+churn, data=p_df)
  
  #Calculate R^2
  #lmg is the R^2 contribution averaged over orderings among regressors
  r2_exp <- calc.relimp(m_exp, type="lmg", rela=FALSE)@R2
  r2_bfs <- calc.relimp(m_bfs, type="lmg", rela=FALSE)@R2
  r2_bugs <- calc.relimp(m_bugs, type="lmg", rela=FALSE)@R2
  
  #Add results to maxtrix
  r2_results[i,] <- c(current_project, r2_exp, r2_bfs, r2_bugs)
  i <- i+1
}



#  The code below is mostly the same as for Table 5, but rela=TRUE in the relimp calculation 
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
  p_df[c("LOC","CC","churn","experience","BFS","num_bugs")] <- lapply(p_df[c("LOC","CC","churn","experience","BFS","num_bugs")], function(x) c(scale(x, center= min(x), scale=diff(range(x)))))
  
  #Build generalized linear models for each dependent variable
  m_exp <- glm(formula = experience ~ LOC+CC+churn, data=p_df)
  m_bfs <- glm(formula = BFS ~ LOC+CC+churn, data=p_df)
  m_bugs <- glm(formula = num_bugs ~ LOC+CC+churn, data=p_df)
  
  #Calculate R^2
  #lmg is the R^2 contribution averaged over orderings among regressors
  lmg_exp <- calc.relimp(m_exp, type="lmg", rela=TRUE)@lmg
  lmg_bfs <- calc.relimp(m_bfs, type="lmg", rela=TRUE)@lmg
  lmg_bugs <- calc.relimp(m_bugs, type="lmg", rela=TRUE)@lmg
  
  
  #Add results to maxtrix
  t6_results[i,] <- c(current_project, "X LOC", lmg_bugs['LOC'], lmg_bfs['LOC'], lmg_exp['LOC'])
  t6_results[i+1,] <- c(current_project, "X CC", lmg_bugs['CC'], lmg_bfs['CC'], lmg_exp['CC'])
  t6_results[i+2,] <- c(current_project, "X churn", lmg_bugs['churn'], lmg_bfs['churn'], lmg_exp['churn'])
  i <- i+3
}













