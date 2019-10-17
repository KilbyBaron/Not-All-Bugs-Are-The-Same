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

final = pd.read_csv(dir+"/intermediate_files/final.csv")

dependents = ['exp','bfs','priority']


final['exp'] = final['exp'] / final['num_post']
#final['bfs'] = final['bfs'] / final['num_post']
final['priority'] = final['priority'] / final['num_post']

final = final.fillna(0)
final.to_csv(dir+"/intermediate_files/avg_final.csv", index=False)



# Same thing for bfc_final
#####################################################################

final = pd.read_csv(dir+"/intermediate_files/bfc_final.csv")

dependents = ['exp','bfs','priority']


final['exp'] = final['exp'] / final['num_post']
#final['bfs'] = final['bfs'] / final['num_post']
final['priority'] = final['priority'] / final['num_post']

final = final.fillna(0)
final.to_csv(dir+"/intermediate_files/avg_bfc_final.csv", index=False)
