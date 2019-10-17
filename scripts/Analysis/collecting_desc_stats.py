import os
import pandas as pd
import numpy as np
import re
import time
import datetime
import math


#Working directory
dir = os.getcwd()+"/.."
os.chdir(dir)


# Function to calculate IQR 
def IQR(a, n): 
  
    a.sort() 
  
    # Index of median of entire data 
    mid_index = median(a, 0, n) 
  
    # Median of first half 
    Q1 = a[median(a, 0, mid_index)] 
  
    # Median of second half 
    Q3 = a[median(a, mid_index + 1, n)] 
  
    # IQR calculation 
    return (Q3 - Q1)


# Function to give index of the median 
def median(a, l, r): 
    n = r - l + 1
    n = (n + 1) // 2 - 1
    return n + l 


def project_IQRs():
    mcrfs = pd.read_csv(dir+"/major_consecutive_releases_files.csv")
    projects = ["accumulo","bookkeeper","camel","cassandra","cxf","derby","felix","hive","openjpa","pig","wicket"]

    for project in projects:
        print(project)
        bfs = mcrfs.loc[mcrfs['project'] == project]['BFS'].tolist()
        print("BFS IQR:",IQR(bfs,len(bfs)))

        mean_exp = mcrfs.loc[mcrfs['project'] == project]['mean_experience'].tolist()
        print("mean_exp IQR:",IQR(mean_exp,len(mean_exp)))

        cost = []
        for x in range(len(bfs)):
            cost.append(bfs[x]*mean_exp[x])
        print("Cost IQR:",IQR(cost,len(cost)))
        print("")



def project_RSDs():
    mcrfs = pd.read_csv(dir+"/major_consecutive_releases_files.csv")
    projects = ["accumulo","bookkeeper","camel","cassandra","cxf","derby","felix","hive","openjpa","pig","wicket"]
    for project in projects:
            print(project)
            bfs = np.array(mcrfs.loc[mcrfs['project'] == project]['BFS'].tolist())
            mean_exp = np.array(mcrfs.loc[mcrfs['project'] == project]['mean_experience'].tolist())
            cost = []
            for x in range(len(bfs)):
                cost.append(bfs[x]*mean_exp[x])
            cost = np.array(cost)

            bfs_s = np.std(bfs)
            exp_s = np.std(mean_exp)
            cost_s = np.std(cost)

            bfs_rsd = (100*bfs_s)/np.mean(bfs)
            exp_rsd = (100*exp_s)/np.mean(mean_exp)
            cost_rsd = (100*cost_s)/np.mean(cost)
            print("BFS RSD:",bfs_rsd)
            print("exp RSD:",exp_rsd)
            print("cost RSD:",cost_rsd)

def count_buggy_files():
    mcrfs = pd.read_csv(dir+"/major_consecutive_releases_files.csv")
    projects = ["accumulo","bookkeeper","camel","cassandra","cxf","derby","felix","hive","openjpa","pig","wicket"]

    for project in projects:
        for x in range(3):
            subset = mcrfs.loc[(mcrfs['project'] == project)&(mcrfs['release_id'] == x)]
            files = set()
            for i,r in subset.iterrows():
                files.add(r['filepath'])
            print(project,x,len(files))
        print("")


def count_num_files():
    for csv in os.listdir(dir+"/intermediate_files/cc_loc/understand_output/"):
        if csv.endswith(".csv"):
            df = pd.read_csv(dir+"/intermediate_files/cc_loc/understand_output/"+csv)
            files = df.loc[df['Kind'] == 'File']
            print(csv,files.shape[0])

def count_jira_issues():

    count = {}

    for csv in os.listdir(dir+"/jira_issues"):
            if csv.endswith(".csv"):
                df = pd.read_csv(dir+"/jira_issues/"+csv)
                proj = df['Project name'].iloc[0]
                for index, row in df.iterrows():
                    key = row['Issue key']
                    if proj in count:
                        count[proj].add(key)
                    else:
                        count[proj] = {key}


    for key in count:
        print(key,len(count[key]))


def count_linked_issues():
    df = pd.read_csv(dir+"/bugfixingcommits.csv")
    count = {}
    for index, row in df.iterrows():
        proj = row['project']
        key = row['bug_id']
        if proj in count:
            count[proj].add(key)
        else:
            count[proj] = {key}
    
    for key in count:
        print(key,len(count[key]))


def count_releases():

    count = {}

    for csv in os.listdir(dir+"/jira_issues"):
            if csv.endswith(".csv"):
                df = pd.read_csv(dir+"/jira_issues/"+csv)
                proj = df['Project name'].iloc[0]
                for index, row in df.iterrows():

                    try:
                        key = row['Fix Version/s']
                        
                        if proj in count:
                            count[proj].add(key)
                        else:
                            count[proj] = {key}
                    except Exception:
                        pass

                    try:
                        key = row['Affects Version/s']
                        
                        if proj in count:
                            count[proj].add(key)
                        else:
                            count[proj] = {key}
                    except Exception:
                        pass



    for key in count:
        print(key,len(count[key]))







