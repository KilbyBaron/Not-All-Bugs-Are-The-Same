import os
import pandas as pd
import numpy as np
import re
import datetime
import math
from datetime import time

"""


"""

def short_path(path):
    split = path.split('/')
    sp = ""
    num_dirs = 4
    for x in range(-1*num_dirs,0):
        if len(split) >= abs(x):
            sp = sp+"/"+split[x]
    return sp


def post_release_issue(release_dates, row):
    commit_date = row['BFC_date']
    major = row['major']
    minor = row['minor']
    #commit_date = pd.to_datetime(date,unit='s')

    v_row = release_dates.loc[(release_dates['major'] == major) & (release_dates['minor'] == minor)]

    post_start = v_row['date'].iloc[0]
    post_end = v_row['post'].iloc[0]

    if commit_date > post_start and commit_date < post_end:
        return 1
    return 0



#Working directory
dir = os.getcwd()+"/.."
os.chdir(dir)

project_names = ["accumulo","bookkeeper","camel","cassandra","cxf","derby","felix","hive","openjpa","pig","wicket"]


#Necessary pre-made data frames
bfc_df = pd.read_csv(dir+"/intermediate_files/target_bfcs.csv")
numstats = pd.read_csv(dir+"/intermediate_files/numstats/all_numstats.csv")
release_dates_df = pd.read_csv(dir+"/intermediate_files/release_dates/version_data.csv")
targets = pd.read_csv(dir+"/intermediate_files/target_releases.csv")

release_dates_df['pre'] = pd.to_datetime(release_dates_df['pre'])
release_dates_df['post'] = pd.to_datetime(release_dates_df['post'])
release_dates_df['date'] = pd.to_datetime(release_dates_df['date'])

bfc_df['BFC_date'] = pd.to_datetime(bfc_df['BFC_date'])

#The final df starts out containing only independent variables
final_df = pd.read_csv(dir+"/intermediate_files/bfc_independent.csv")


for project_name in project_names:

    #Divide dataframes by project to make searching faster
    project_bfcs = bfc_df.loc[bfc_df['project'] == project_name.upper()]
    project_releases = release_dates_df.loc[release_dates_df['project'] == project_name]
    project_numstats = numstats.loc[numstats['project'] == project_name]
    counter = 0

    for index, row in project_bfcs.iterrows():

        print(project_name,":  ",counter,"/",project_bfcs.shape[0], end="\r")
        counter += 1
        
        #get numstat subset
        commit_numstats = project_numstats.loc[project_numstats['hash'] == row['BFC_id']]

        #Get version info
        target_versions = sorted(targets.loc[targets['project'] == project_name]['minor'].tolist())
        pre_post = post_release_issue(project_releases, row)
        
        #If the commit happened in the post release period, add the dependent variables to the final dataframe
        if pre_post == 1:
            for i,r in commit_numstats.iterrows():
                final_row = final_df.loc[(final_df['filepath'] == r['filepath']) & (final_df['minor'] == row['minor'])]
                final_df.loc[(final_df['filepath'] == r['filepath']) & (final_df['minor'] == row['minor']),'num_post'] = final_row['num_post'] + 1
                final_df.loc[(final_df['filepath'] == r['filepath']) & (final_df['minor'] == row['minor']),'exp'] = final_row['exp'] + row['author_exp']
                final_df.loc[(final_df['filepath'] == r['filepath']) & (final_df['minor'] == row['minor']),'priority'] = final_row['priority'] + row['priority']
                final_df.loc[(final_df['filepath'] == r['filepath']) & (final_df['minor'] == row['minor']),'bfs'] = final_row['bfs'] + r['la'] + r['ld']
                final_df.loc[(final_df['filepath'] == r['filepath']) & (final_df['minor'] == row['minor']),'num_bugs'] = final_row['num_bugs'] + 1
                final_df.loc[(final_df['filepath'] == r['filepath']) & (final_df['minor'] == row['minor']),'release_id'] = target_versions.index(int(row['minor']))
    print("")
            
       

final_df.to_csv(dir+"/intermediate_files/bfc_final.csv", index=False)







