import os
import pandas as pd
import numpy as np
import re
import datetime
import math
from datetime import time

from sklearn import preprocessing


#Working directory
dir = os.getcwd()+"/.."
os.chdir(dir)

project_names = ["accumulo","bookkeeper","camel","cassandra","cxf","derby","felix","hive","openjpa","pig","wicket"]


df = pd.read_csv(dir+"/intermediate_files/final_dataset.csv")

df['cost'] = df['priority']*df['exp']*df['bfs']
min_max_scaler = preprocessing.MinMaxScaler()
df['cost'] = min_max_scaler.fit_transform(df['cost'].values.reshape(-1,1))
df['cost'] = df['cost'].apply(lambda x : math.ceil(x*100))


df.to_csv(dir+"/intermediate_files/final_dataset.csv", index=False)




