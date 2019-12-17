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
file_data <- read.csv("/home/kjbaron/Documents/NABATS/intermediate_files/bug_level_df.csv", header = TRUE)



# -1 indicates a strong negative correlation : this means that every time x increases, y decreases (left panel figure)
#  0 means that there is no association between the two variables (x and y) (middle panel figure)
#  1 indicates a strong positive correlation : this means that y increases with x (right panel figure)

res <- cor.test(file_data$priority, file_data$exp, method = "pearson")



################################################################################
# Fill Correlation Table
################################################################################

#Create a matrix to fill with correlation values
cor_mat <- matrix(ncol=13, nrow=4)
cor_mat[1,] <- c("M1","M2", "accumulo","bookkeeper","camel","cassandra","cxf","derby","felix","hive","openjpa","pig","wicket")
cor_mat[,1] <- c("M1","Exp","Exp","Priority")
cor_mat[,2] <- c("M2","BFS","Priority","BFS")


i <- 3
for (current_project in c("accumulo","bookkeeper","camel","cassandra","cxf","derby","felix","hive","openjpa","pig","wicket"))
{
  print(current_project)
  
  #Extract project
  p_df <- filter(file_data, project == current_project)
  p_df[c("exp","bfs","priority")] <- lapply(p_df[c("exp","bfs","priority")], function(x) c(scale(x, center= min(x), scale=diff(range(x)))))
  
  
  pri_exp <- cor.test(p_df$priority, p_df$exp, method = "pearson")
  bfs_exp <- cor.test(p_df$bfs, p_df$exp, method = "pearson")
  bfs_pri <- cor.test(p_df$bfs, p_df$priority, method = "pearson")
 
  #Add results to maxtrix
  cor_mat[2,i] <- bfs_exp$estimate
  cor_mat[3,i] <- pri_exp$estimate
  cor_mat[4,i] <- bfs_pri$estimate

  i <- i+1
}


write.csv(cor_mat, file = "/home/kjbaron/Documents/NABATS/intermediate_files/dependent_variable_correlations.csv",row.names=FALSE,na="")
























