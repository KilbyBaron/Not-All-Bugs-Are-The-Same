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






#Working directory
dir = os.getcwd()+"/.."
os.chdir(dir)

independent = pd.read_csv(dir+"/intermediate_files/independent.csv")


independent['filepath'] = independent['filepath'].apply(short_path)

independent.to_csv(dir+"/intermediate_files/independent.csv")

