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


harold_final = pd.read_csv(dir+"/HAROLD/project-misclassified-files/experiments-fn-files/dataset-all-projects.csv")


project_names = ["accumulo","bookkeeper","camel","cassandra","cxf","derby","felix","hive","openjpa","pig","wicket"]

for p in project_names:
    
    p_path_head = harold_final.loc[harold_final['project'] == p].head()
    
    print(p)
    for i,r in p_path_head.iterrows():
        print(r['path'])
        
    print("\n\n")
