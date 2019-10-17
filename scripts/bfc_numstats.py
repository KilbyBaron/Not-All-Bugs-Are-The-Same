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


target_bfcs = pd.read_csv(dir+"/intermediate_files/target_bfcs.csv")
numstats = pd.read_csv(dir+"/intermediate_files/numstats/all_numstats.csv")

target_hashes = set(target_bfcs['BFC_id'])
target_numstats = numstats.loc[numstats['hash'].isin(target_hashes)]

target_numstats.to_csv(dir+"/intermediate_files/numstats/target_numstats.csv")
