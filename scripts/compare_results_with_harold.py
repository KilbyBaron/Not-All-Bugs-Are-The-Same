import os
import pandas as pd
import numpy as np
import re
import time
import datetime
import math



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

harold = pd.read_csv(dir+"/HAROLD/project-misclassified-files/experiments-fn-files/dataset-all-projects.csv")
me = pd.read_csv(dir+"/intermediate_files/avg_final.csv")

found = 0
not_found = 0

comp_df = pd.DataFrame(columns = ['project','file','rel','h_LOC','k_LOC','h_CC','k_CC', 'h_bfs','k_bfs','h_churn','k_churn','h_num_pre','k_num_pre','h_num_post','k_num_post','h_exp','k_exp','h_num_bugs','k_num_bugs'])



h_num_b0 = harold.loc[harold['num_issues']==0].shape[0]
k_num_b0 = me.loc[me['num_bugs']==0].shape[0]

h_num_b0 = harold.loc[harold['num_issues']==0].shape[0]
k_num_b0 = me.loc[me['num_bugs']==0].shape[0]

h_num_b0 = harold.loc[harold['num_issues']==0].shape[0]
k_num_b0 = me.loc[me['num_bugs']==0].shape[0]


print("harold num rows:",harold.shape[0])
print("me num rows:",me.shape[0])
print("")
print("harold num rows with 0 bugs:",h_num_b0)
print("me num rows with 0 bugs:",k_num_b0)
print("")
print("harold num rows with >0 bugs:",harold.shape[0]-h_num_b0)
print("me num rows with >0 bugs:",me.shape[0]-k_num_b0)


diffs = {}

for hi,hr in harold.iterrows():

    print(str(hi)+"/"+str(harold.shape[0]), end="\r")

    try:

        h_fname = hr['path'].split("/")[-1]
        project = hr['project']
        major = int(hr['release_name'].split('.')[0])
        minor = int(hr['release_name'].split('.')[1])

        match_found = False
        match_search = me.loc[(me['project'] == project) & (me['filename'] == h_fname) & (me['major'] == major) & (me['minor'] == minor)]

        if match_search.shape[0] > 0:
            for mi,mr in match_search.iterrows():
                if short_path(hr['path']) == short_path(mr['filepath']):
                    match = mr
                    match_found = True
                    break


        if match_found:



            comp_df = comp_df.append({
                'project':project,
                'file':short_path(hr['path']),
                'rel':hr['release_name'],
                'h_LOC':hr['lines'],
                'k_LOC':match['LOC'],
                'h_CC':hr['cyclomatic'],
                'k_CC':match['CC'],
                'h_bfs':hr['changed_lines'],#not sure if this column is bfs in harold's.....
                'k_bfs':match['bfs'],
                'h_churn':hr['churn'],
                'k_churn':match['churn'],
                'h_num_pre':hr['num_pre_release_issues'],
                'k_num_pre':match['num_pre'],
                'h_num_post':hr['post_num_commits'],
                'k_num_post':match['num_post'],
                'h_exp':hr['mean_experience'],
                'k_exp':match['exp'],
                'h_num_bugs':hr['num_issues'],
                'k_num_bugs':match['num_bugs']
            },ignore_index=True)
    
    except Exception as e:
        pass




comp_df.to_csv(dir+"/intermediate_files/harold_comparison/avg_bfc_comparing_with_harold.csv")



