import os
import pandas as pd
import numpy as np
import re
import time
import datetime
import math
import matplotlib.pyplot as plt



#Working directory
dir = os.getcwd()+"/.."
os.chdir(dir)



#projects = ["accumulo","bookkeeper","camel","cassandra","cxf","derby","felix","hive","openjpa","pig","wicket"]
projects=['felix']
for p in projects:

    if not os.path.exists(dir+"/intermediate_files/Analysis/Figures/"+p):
        os.mkdir(dir+"/intermediate_files/Analysis/Figures/"+p)

    p_df = pd.read_csv(dir+"/intermediate_files/Analysis/"+p+"_standardized.csv")
    df = pd.DataFrame()


    step_size = 0.001

    for y in range(1000):

        x = y*step_size
        
        LOC = p_df.loc[(p_df['LOC']>=x)&(p_df['LOC']<x+step_size)]
        CC = p_df.loc[(p_df['CC']>=x)&(p_df['CC']<x+step_size)]
        churn = p_df.loc[(p_df['churn']>=x)&(p_df['churn']<x+step_size)]            

        df = df.append({
        "num":y,
        
        "LOC":LOC.shape[0],
        "CC":CC.shape[0],
        "churn":churn.shape[0],    
        
        "avg_numbugs_LOC":LOC['num_bugs'].mean(),
        "avg_numbugs_CC":CC['num_bugs'].mean(),
        "avg_numbugs_churn":churn['num_bugs'].mean(),
         
        "avg_exp_LOC":LOC['exp'].mean(),
        "avg_exp_CC":CC['exp'].mean(),
        "avg_exp_churn":churn['exp'].mean(),
        
        "avg_bfs_LOC":LOC['bfs'].mean(),
        "avg_bfs_CC":CC['bfs'].mean(),
        "avg_bfs_churn":churn['bfs'].mean()
        
        }
        ,ignore_index=True)


    for c in df.columns.values:
        plt.figure()
        x = range(1000)
        y = df[c]

        plt.scatter(x, y, alpha=0.5)
        plt.title(c)
        plt.xlabel('Range (step size:'+str(step_size)+')')
        plt.ylabel('Normalized value')
        plt.savefig(dir+"/intermediate_files/Analysis/Figures/"+p+"/test/all/"+c+'.png')
        plt.ylim(0,1)
        plt.close()






