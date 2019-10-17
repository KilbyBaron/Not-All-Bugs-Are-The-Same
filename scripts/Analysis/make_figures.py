import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import statistics
import os



"""

IMPORTANT NOTE:

Figures for fig2 are a bit different than originals. I counted # bugs for dev exp and counted # files for BFS and cost.

ASK GEMA if I should do all at file level?

"""


dir = "/home/kjbaron/Documents/NABATS/"

mcrfs = pd.read_csv(dir+"major_consecutive_releases_files.csv")
mcrfs = mcrfs.loc[mcrfs['BFS'] > 0]
projects = ["accumulo","bookkeeper","camel","cassandra","cxf","derby","felix","hive","openjpa","pig","wicket"]


def cost_calc(l1, l2):
    cost = []
    for x in range(len(l1)):
        cost.append(l1[x]*l2[x])
    return cost

def figure1():
    bfs = []
    exp = []
    cost = []

    for project in projects:
        bfs_list = mcrfs.loc[mcrfs['project'] == project]['BFS'].tolist()
        exp_list = mcrfs.loc[mcrfs['project'] == project]['mean_experience'].tolist()
        print(min(exp_list))
        bfs.append(bfs_list)
        exp.append(exp_list)
        cost.append(cost_calc(exp_list, bfs_list))

    plt.figure()
    plt.boxplot(bfs)
    plt.yscale('log')
    plt.xticks(range(1,12), projects)
    plt.ylabel("Bug Fix Size")

    plt.figure()
    plt.boxplot(exp)
    plt.yscale('symlog')
    plt.xticks(range(1,12), projects)
    plt.ylabel("Dev Experience")

    plt.figure()
    plt.boxplot(cost)
    plt.yscale('symlog')
    plt.xticks(range(1,12), projects)
    plt.ylabel("Cost")

    plt.show()




def bar_chart(list, x_label, y_label, project):
    counts = []
    num_groups = 10
    scale = int(max(list)/num_groups)
    scale = scale+(10-scale%10)

    if x_label == "Cost":
        scale = 1000


    for x in range(1,11):
        counts.append(len([i for i in list if i > (x-1)*scale and i < (x*scale)]))

    plt.figure()
    #fig, ax = plt.subplots()
    plt.bar(range(num_groups), counts)
    plt.xticks(range(1,num_groups+1), range(scale, int(max(list)), scale))
    plt.ylabel(y_label)
    plt.xlabel(x_label)
    plt.title(project)
    plt.tight_layout()



    plt.savefig(dir+"Figures/Figure2/"+project+'_'+x_label+'.png')



def figure2():
    for project in projects:
        p_df = mcrfs.loc[mcrfs['project'] == project]

        #Exp will be the same for all files so just look for the mean exp from the first occurance of each bug_id
        exp_dict = dict()
        exps = []
        bfss = []
        costs = []
        max_bfs = 100
        max_cost = 10000
        for index, row in p_df.iterrows():
            if row['bug_id'] in exp_dict:
                exp_dict[row['bug_id']].append(row['mean_experience'])
            else:
                exp_dict[row['bug_id']] = [row['mean_experience']]

            if row['BFS'] < max_bfs:
                bfss.append(row['BFS'])

            cost = row['BFS']*row['mean_experience']
            if cost < max_cost:
                costs.append(cost)

        for key in exp_dict:
            exps.append(statistics.mean(exp_dict[key]))


        bar_chart(exps, "Dev_Experience", "#_Bugs", project)
        bar_chart(bfss, "Bug_Fix_Size", "#_Bugs", project)
        bar_chart(costs, "Cost", "#_Bugs", project)


figure1()
