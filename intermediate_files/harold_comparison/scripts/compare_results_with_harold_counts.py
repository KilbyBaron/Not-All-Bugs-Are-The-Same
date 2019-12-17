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
    
def get_type(path):
    split = path.split('.')
    return split[-1]


def specific_path(path):
    sub = "src/core/src/main/java/org/apache/accumulo/core"
    if sub in path:
        return 1
    return 0
    
def contains_test(path):
    if "/test/" in path:
        return 1
    return 0
    
def contains_src(path):
    if "/home/kjbaron/Documents/NABATS/cloned_repos/accumulo-1.4.0/src/" in path:
        return 1
    return 0
    
    



#Working directory
dir = os.getcwd()+"/.."
os.chdir(dir)

all_harold = pd.read_csv(dir+"/intermediate_files/harold_comparison/normalized_final_harold.csv")
all_harold['shortpath'] = all_harold['path'].apply(short_path)
all_me = pd.read_csv(dir+"/intermediate_files/harold_comparison/normalized_final.csv")

me_final = pd.read_csv(dir+"/intermediate_files/final.csv")
harold_final = pd.read_csv(dir+"/HAROLD/project-misclassified-files/experiments-fn-files/dataset-all-projects.csv")
harold_final['shortpath'] = harold_final['path'].apply(short_path)






#######################################################
# Comparing accumulo files bettween me and harold
#######################################################

me_accumulo = all_me.loc[all_me['project'] == 'accumulo']
harold_accumulo = all_harold.loc[all_harold['project'] == 'accumulo']

intersection = set(harold_accumulo['shortpath']) & set(me_accumulo['filepath'])

kilby_diff = set(me_accumulo['filepath']).difference(intersection)
harold_diff = set(harold_accumulo['shortpath']).difference(intersection)


#print("Kilby diff:",len(kilby_diff))
#print("Harold diff:",len(harold_diff))



#########################################################
# Trying to find out why I have more files than Harold
#########################################################

understand_accumulo_1_4 = pd.read_csv(dir+"/intermediate_files/accumulo_1_4_src.csv")
understand_accumulo_1_4 = understand_accumulo_1_4.loc[understand_accumulo_1_4['Kind'] == 'File']
understand_accumulo_1_4['shortpath'] = understand_accumulo_1_4['Name'].apply(short_path)
understand_accumulo_1_4['type'] = understand_accumulo_1_4['Name'].apply(get_type)
understand_accumulo_1_4['subpath'] = understand_accumulo_1_4['Name'].apply(specific_path)
understand_accumulo_1_4['containstest'] = understand_accumulo_1_4['Name'].apply(contains_test)


#try filtering path down further
#understand_accumulo_1_4 = understand_accumulo_1_4.loc[understand_accumulo_1_4['containstest'] ==0]


#Get harold's types and filter understand output accordingly
h_types = set(all_harold['path'].apply(get_type)) #HE ONLY COLLECTS JAVA FILES FOR ALL PROJECTS!!!
understand_accumulo_1_4 = understand_accumulo_1_4.loc[understand_accumulo_1_4['type'] == 'java']

#Get me and harolds orginal data for accumulo 1.4
harold_accumulo_14 = harold_accumulo.loc[harold_accumulo['release_name'] == '1.4.0']
me_accumulo_14 = me_accumulo.loc[me_accumulo['minor'] == 4]
#me_accumulo_14['src'] = me_accumulo_14['filepath'].apply(contains_src)
#me_accumulo_14 = me_accumulo_14.loc[me_accumulo_14['src'] == 1]

#Get intersection of files between harold&understand and harold&me
ua_14_files = set(understand_accumulo_1_4['shortpath'])
ua_intersection = set(harold_accumulo_14['shortpath']) & ua_14_files
me_intersection = set(harold_accumulo_14['shortpath']) & set(me_accumulo_14['filepath'])

#Get difference in files between harold&understand and harold&me
ua_diff = set(ua_14_files).difference(ua_intersection)
me_diff = set(me_accumulo_14['filepath']).difference(me_intersection)




print("")
print("Total number of files in accumulo1.4:")
print("Harold:",len(set(harold_accumulo_14['shortpath'])))
print("New:",len(ua_14_files))
print("Old:",len(set(me_accumulo_14['filepath'])))
print("----")
print("Size of intersection with Harold:")
print("New:",len(ua_intersection))
print("Old:",len(me_intersection))
print("----")
print("Size of difference:")
print("New:",len(ua_diff))
print("Old:",len(me_diff))
print("")





#Trying to find which folders Harold is excluding
'''
unmatched_folders = set()
h_paths = set(harold_accumulo_14['path'])

for i,r in understand_accumulo_1_4.iterrows():
    if r['shortpath'] in ua_diff:
        #print(r['Name'].replace("/home/kjbaron/Documents/NABATS/cloned_repos/accumulo-1.4.0/",""))
        folder = r['Name'].replace("/home/kjbaron/Documents/NABATS/cloned_repos/accumulo-1.4.0/","")
        split = folder.split('/')
        folder = folder.replace(split[-1],'')
        folder = folder.replace(split[-2]+"/","")
        unmatched_folders.add(folder)

 

      
for p in h_paths:
    #print(p)
    if "/test/" in p:
        print(1)
    folder = p.replace(p.split('/')[-1],'')
    if folder in unmatched_folders:
        unmatched_folders.remove(folder)



#for f in unmatched_folders:
#    print(f)

'''
'''

inpath = 0
notinpath = 0
for path in h_paths:
    sub = "src/core/src/main/java/org/apache/accumulo/core"
    
    if sub in path:
        inpath += 1
    else:
        notinpath += 1
        print(path)

print("in:",inpath)
print("notinpath:",notinpath)

'''





'''

this worked!
find out why I have so many files that harold doesnt!

##################################################################################
# Making alternate dataset where accumulo only has the same files as harold
##################################################################################

#Remove all accumulo rows
new_kilby_final = me_final.loc[me_final['project'] != 'accumulo']

for i,r in me_accumulo.iterrows():
    
    if r['filepath'] in intersection:
        new_kilby_final = new_kilby_final.append(r,ignore_index=True)



new_kilby_final.to_csv(dir+"/intermediate_files/final_accumulo_file_test.csv")
'''

































