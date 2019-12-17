import os
import pandas as pd
import numpy as np
import re
import time
import datetime
import math

import matplotlib.pyplot as plt



def short_path(path):
    split = path.split('/')
    sp = ""
    num_dirs = 4
    for x in range(-1*num_dirs,0):
        if len(split) >= abs(x):
            sp = sp+"/"+split[x]
    return sp


#Working directory
dir = os.getcwd()+"/.."
os.chdir(dir)

all_harold = pd.read_csv(dir+"/intermediate_files/harold_comparison/normalized_final_harold.csv")
all_me = pd.read_csv(dir+"/intermediate_files/harold_comparison/normalized_final.csv")

me_final = pd.read_csv(dir+"/intermediate_files/final.csv")
harold_final = pd.read_csv(dir+"/HAROLD/project-misclassified-files/experiments-fn-files/dataset-all-projects.csv")



#################################
#Analysing original data
#################################


#Kilby

independent = ['LOC','CC','churn']
dependent = ['num_bugs','exp','bfs']

for i in independent:
    for d in dependent:
        plt.figure()
        x = me_final[i]
        y = me_final[d]

        plt.scatter(x, y, alpha=0.5)
        plt.title("kilby_"+i+"_vs_"+d)
        plt.xlabel(i)
        plt.ylabel(d)
        plt.savefig(dir+"/intermediate_files/harold_comparison/Figures/all/original/kilby_"+i+"_vs_"+d+".png")
        plt.ylim(0,1)
        plt.close()
 
 
#Harold       
        
independent = ['lines','cyclomatic','churn']
dependent = ['num_issues','mean_experience','changed_lines']

for i in independent:
    for d in dependent:
        plt.figure()
        x = harold_final[i]
        y = harold_final[d]

        plt.scatter(x, y, alpha=0.5)
        plt.title("harold_"+i+"_vs_"+d)
        plt.xlabel(i)
        plt.ylabel(d)
        plt.savefig(dir+"/intermediate_files/harold_comparison/Figures/all/original/harold_"+i+"_vs_"+d+".png")
        plt.ylim(0,1)
        plt.close()  




#############################
#Analyzing normalized data by project
#############################



'''

projects = ["accumulo","bookkeeper","camel","cassandra","cxf","derby","felix","hive","openjpa","pig","wicket"]

step_size = 0.00001

for p in projects:

    comp_df = pd.DataFrame(columns = ["num","harold_LOC","kilby_LOC", "harold_avg_numbugs_LOC","kilby_avg_numbugs_LOC","harold_CC","kilby_CC"])
    
    harold = all_harold.loc[all_harold['project'] == p]
    me = all_me.loc[all_me['project']==p]

    for y in range(200):
        x = y*step_size
        
        
        h_LOC = harold.loc[(harold['lines']>=x)&(harold['lines']<x+step_size)]
        k_LOC = me.loc[(me['LOC']>=x)&(me['LOC']<x+step_size)]
        
        h_CC = harold.loc[(harold['cyclomatic']>=x)&(harold['cyclomatic']<x+step_size)]
        k_CC = me.loc[(me['CC']>=x)&(me['CC']<x+step_size)]
        
        h_churn = harold.loc[(harold['churn']>=x)&(harold['churn']<x+step_size)]
        k_churn = me.loc[(me['churn']>=x)&(me['churn']<x+step_size)]    
        

        comp_df = comp_df.append({
        "num":y,
        "harold_LOC":h_LOC.shape[0],
        "kilby_LOC":k_LOC.shape[0],
        "harold_CC":h_CC.shape[0],
        "kilby_CC":k_CC.shape[0],
        "harold_churn":h_churn.shape[0],
        "kilby_churn":k_churn.shape[0],    
        
        "harold_avg_numbugs_LOC":h_LOC['num_issues'].mean(),
        "kilby_avg_numbugs_LOC":k_LOC['num_bugs'].mean(),
        "harold_avg_numbugs_CC":h_CC['num_issues'].mean(),
        "kilby_avg_numbugs_CC":k_CC['num_bugs'].mean(),
        "harold_avg_numbugs_churn":h_churn['num_issues'].mean(),
        "kilby_avg_numbugs_churn":k_churn['num_bugs'].mean(),
         
        "harold_avg_exp_LOC":h_LOC['mean_experience'].mean(),
        "kilby_avg_exp_LOC":k_LOC['exp'].mean(),
        "harold_avg_exp_CC":h_CC['mean_experience'].mean(),
        "kilby_avg_exp_CC":k_CC['exp'].mean(),
        "harold_avg_exp_churn":h_churn['mean_experience'].mean(),
        "kilby_avg_exp_churn":k_churn['exp'].mean(),
        
        "harold_avg_bfs_LOC":h_LOC['changed_lines'].mean(),
        "kilby_avg_bfs_LOC":k_LOC['bfs'].mean(),
        "harold_avg_bfs_CC":h_CC['changed_lines'].mean(),
        "kilby_avg_bfs_CC":k_CC['bfs'].mean(),
        "harold_avg_bfs_churn":h_churn['changed_lines'].mean(),
        "kilby_avg_bfs_churn":k_churn['bfs'].mean()
        
        }
        ,ignore_index=True)

    for c in comp_df.columns.values:
        plt.figure()
        x = range(200)
        y = comp_df[c]

        plt.scatter(x, y, alpha=0.5)
        plt.title(c)
        plt.xlabel('Range (step size:'+str(step_size)+')')
        plt.ylabel('Normalized value')
        plt.savefig(dir+"/intermediate_files/harold_comparison/Figures/"+p+"/"+c+'.png')
        plt.ylim(0,1)
        plt.close()
        
    del comp_df


'''



