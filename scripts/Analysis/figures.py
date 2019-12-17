import os
import pandas as pd
import numpy as np
import re
import time
import datetime
import math


import matplotlib.pyplot as plt
import statistics
import os

from sklearn import preprocessing


"""

This script is used to make the figures for the paper. It outputs the figures to the Figures 
folder.

"""


projects = ["accumulo","bookkeeper","camel","cassandra","cxf","derby","felix","hive","openjpa","pig","wicket"]

#Working directory
dir = os.getcwd()+"/../../"
os.chdir(dir)


def make_bug_lvl_df():


	if os.path.exists(dir+"/intermediate_files/bfc_df.csv"):
		commit_df = pd.read_csv(dir+"/intermediate_files/bfc_df.csv")

	else:
		print("Creating the bug level dataframe...")

		bfcs = pd.read_csv(dir+"intermediate_files/target_bfcs.csv")
		numstats = pd.read_csv(dir+"intermediate_files/numstats/all_numstats.csv")

		commit_df = pd.DataFrame(columns=['project','id','bfs','exp','priority','cost'])

		#Get commit level dataframe
		
		for i,r in bfcs.iterrows():
			mean_exp=r['author_exp']
			pri = r['priority']

			bfs = 0
			bug_numstats = numstats.loc[numstats['hash'] == r['BFC_id']]
			for ni,nr in bug_numstats.iterrows():
				bfs += nr['la'] + nr['ld']
				break
				
			cost = bfs*mean_exp*pri
			
			if bfs>0:
				commit_df = commit_df.append({
				'project':r['project'].lower(),
				'id':r['bug_id'],
				'bfs':bfs,
				'exp':mean_exp,
				'priority':pri,
				'cost':cost
				},ignore_index=True)
		
		commit_df.to_csv(dir+"/intermediate_files/bfc_df.csv", index=False)
	



	commit_df = pd.read_csv(dir+"/intermediate_files/bfc_df.csv")
	
	
	
	
	
	
	#Combine commits to make bug level dataframe
	
	bug_mean_df = commit_df.groupby(['id']).mean()[['exp','priority']]
	bug_sum_df = commit_df.groupby(['id']).sum()['bfs']
	
	
	bug_df = bug_mean_df.join(bug_sum_df)
	bug_df = bug_df.join(commit_df.set_index('id')['project']).reset_index()
	
	min_max_scaler = preprocessing.MinMaxScaler()
	
	
	cost_dfs = []
	
	for p in projects:
		p_bug_df = bug_df.loc[bug_df['project']==p].copy()
		
		p_bug_df['exp'] = p_bug_df['exp'].apply(lambda x: x+1) #Add 1 to avoid zeroes
		p_bug_df['norm_exp'] = min_max_scaler.fit_transform(p_bug_df['exp'].values.reshape(-1,1))
		p_bug_df['norm_priority'] = min_max_scaler.fit_transform(p_bug_df['priority'].values.reshape(-1,1))
		p_bug_df['norm_bfs'] = min_max_scaler.fit_transform(p_bug_df['bfs'].values.reshape(-1,1))
		
		p_bug_df['cost'] = (1+p_bug_df['norm_priority'])*(1+p_bug_df['exp'])*(1+p_bug_df['bfs'])
		p_bug_df['cost'] = min_max_scaler.fit_transform(p_bug_df['cost'].values.reshape(-1,1))
		p_bug_df['cost'] = p_bug_df['cost']*100
		
		cost_dfs.append(p_bug_df)
		

	bug_df = pd.concat(cost_dfs)
	
	
	#print(bug_df['cost'])
	
		
	bug_df.to_csv(dir+"/intermediate_files/bug_level_df.csv")
	

	return bug_df
		




dir = "/home/kjbaron/Documents/NABATS/"

df = make_bug_lvl_df()
projects = ["accumulo","bookkeeper","camel","cassandra","cxf","derby","felix","hive","openjpa","pig","wicket"]




def figure1():
	bfs = []
	exp = []
	cost = []
	pri = []

	for project in projects:
		bfs_list = df.loc[df['project'] == project]['bfs'].tolist()
		exp_list = df.loc[df['project'] == project]['exp'].tolist()
		cost_list = df.loc[df['project'] == project]['cost'].tolist()
		pri_list = df.loc[df['project'] == project]['priority'].tolist()
		
		bfs.append(bfs_list)
		exp.append(exp_list)
		cost.append(cost_list)
		pri.append(pri_list)

	plt.figure(figsize=(11, 3))
	plt.boxplot(bfs)
	plt.yscale('log')
	plt.xticks(range(1,12), projects)
	plt.ylabel("Bug Fix Size")
	plt.savefig(dir+"Figures&Tables/Figure1/BFS_Boxplots.png")

	plt.figure(figsize=(11, 3))
	plt.boxplot(exp)
	plt.yscale('symlog')
	plt.xticks(range(1,12), projects)
	plt.ylabel("Dev Experience")
	plt.savefig(dir+"Figures&Tables/Figure1/EXP_Boxplots.png")

	plt.figure(figsize=(11, 3))
	plt.boxplot(cost)
	plt.yscale('symlog')
	plt.xticks(range(1,12), projects)
	plt.ylabel("Cost")
	plt.savefig(dir+"Figures&Tables/Figure1/COST_Boxplots.png")
	
	print("Updated box plots")




#############################

	priorities = [[],[],[],[],[]] #for boxplot
	p2 = [] #for scatterplot
	py = []

	for p in projects:
		p_df = df.loc[df['project'] == p]
		for x in range(1,6):
			priorities[x-1].append(p_df.loc[p_df['priority']==x].shape[0]) #for boxplot
			p2.append(p_df.loc[p_df['priority']==x].shape[0]) #for scatterplot
			py.append(x)
			

	for pp in priorities:
		print(sum(pp)/11)

	plt.figure(figsize=(5, 2))
	plt.boxplot(priorities)
	#plt.yscale('symlog')
	plt.xticks(range(1,6), range(1,6))
	plt.ylabel("Priority")
	plt.savefig(dir+"Figures&Tables/Figure1/PRIORITY_Boxplots.png")
	
	plt.figure(figsize=(5, 2))
	plt.scatter(py,p2)
	#plt.yscale('symlog')
	#plt.xticks(range(1,6), range(1,6))
	plt.ylabel("Priority")
	plt.savefig(dir+"Figures&Tables/Figure1/PRIORITY_scatter.png")




def bar_chart(list, x_label, y_label, project):
	counts = []
	num_groups = 10
	scale = int(max(list)/num_groups)
	scale = scale+(10-scale%10)

	if x_label == "Cost":
		scale = 1


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



	plt.savefig(dir+"Figures&Tables/Figure2/"+project+'_'+x_label+'.png')
	print("Updated Figure2/"+project+'_'+x_label+'.png')


def figure2():
	for project in projects:
		
		p_df = df.loc[df['project'] == project]

		
		
		#The maximums are required because we can only show a certain number of bars. 
		#I got the maximums from the old charts
		max_bfs = 100
		max_cost = 10

		#Exp will be the same for all files so just look for the mean exp from the first occurance of each bug_id
		exp_dict = dict()
		exps = p_df['exp'].tolist()
		bfss = p_df.loc[p_df['bfs'] < max_bfs]['bfs'].tolist()
		costs = p_df.loc[p_df['cost'] < max_cost]['cost'].tolist()
		#costs2 = p_df.loc[p_df['cost'] < max_cost2]['cost'].tolist()
		


		bar_chart(exps, "Dev_Experience", "#_Bugs", project)
		bar_chart(bfss, "Bug_Fix_Size", "#_Bugs", project)
		bar_chart(costs, "Cost", "#_Bugs", project)
		#bar_chart(costs2, "Cost_TEST", "#_Bugs", project)




def figure3():

	#Make inital BFS df
	bfs_lines_x = []
	for x in range(15):
		bfs_lines_x.append(2**x)
	bfs_line_df = pd.DataFrame({'x': bfs_lines_x})
	
	#Make initial cost df
	cost_lines_x = []
	for x in range(-10,10):
		cost_lines_x.append(2**x)
	cost_line_df = pd.DataFrame({'x': cost_lines_x})
	
	
	#Make initial exp df
	exp_lines_x = []
	for x in range(15):
		exp_lines_x.append(2**x)
	exp_line_df = pd.DataFrame({'x': exp_lines_x})
	print(exp_lines_x)
	
	
	#Add counts for each project to df
	for p in projects:
		p_df = df.loc[df['project'] == p]
		
		#Counting BFS
		counts = []	
		bar_min = 0
		for bar_max in bfs_lines_x:
			count = p_df.loc[(p_df['bfs']<bar_max) & (p_df['bfs']>=bar_min)].shape[0]
			bar_min = bar_max
			counts.append(count)
		bfs_line_df[p] = counts
		
		
		#Counting BFS
		counts = []	
		bar_min = 0
		for bar_max in cost_lines_x:
			count = p_df.loc[(p_df['cost']<bar_max) & (p_df['cost']>=bar_min)].shape[0]
			bar_min = bar_max
			counts.append(count)
		cost_line_df[p] = counts
		
		
		
		#Counting EXP
		counts = []	
		bar_min = 0
		for bar_max in exp_lines_x:
			count = p_df.loc[(p_df['exp']<bar_max) & (p_df['exp']>=bar_min)].shape[0]
			bar_min = bar_max
			counts.append(count)
		exp_line_df[p] = counts

	
	
	
	######################################################################################
	
	
	
	#Turn df into line plot
	plt.figure()
	
	# style
	plt.style.use('ggplot')
	
	ax = plt.gca()
	ax.set_xscale('log')
	 
	# create a color palette
	palette = plt.get_cmap('tab20')
	 
	# multiple line plot
	num=0
	for column in bfs_line_df.drop('x', axis=1):
		num+=1
		plt.plot(bfs_line_df['x'], bfs_line_df[column], marker='o', color=palette(num), linewidth=2, alpha=0.9, label=column)
	 
	# Add legend
	plt.legend(loc=0, ncol=1)
	 
	# Add titles
	plt.xlabel("BFS")
	plt.ylabel("Number of Bugs")
	
	plt.savefig(dir+"Figures&Tables/BFS_line.png")
	
	
	
	
	
	
	
######################################################################################
	
	
	
	#Turn df into line plot
	plt.figure()
	
	# style
	plt.style.use('ggplot')
	
	ax = plt.gca()
	ax.set_xscale('log')
	 
	# create a color palette
	palette = plt.get_cmap('tab20')
	 
	# multiple line plot
	num=0
	for column in cost_line_df.drop('x', axis=1):
		num+=1
		plt.plot(cost_line_df['x'], cost_line_df[column], marker='o', color=palette(num), linewidth=2, alpha=0.9, label=column)
	 
	# Add legend
	plt.legend(loc=0, ncol=1)
	 
	# Add titles
	plt.xlabel("Cost")
	plt.ylabel("Number of Bugs")
	
	plt.savefig(dir+"Figures&Tables/cost_line.png")


	
		
######################################################################################
	
	
	
	#Turn df into line plot
	plt.figure()
	
	# style
	plt.style.use('ggplot')
	
	ax = plt.gca()
	ax.set_xscale('log')
	 
	# create a color palette
	palette = plt.get_cmap('tab20')
	 
	# multiple line plot
	num=0
	for column in exp_line_df.drop('x', axis=1):
		num+=1
		plt.plot(exp_line_df['x'], exp_line_df[column], marker='o', color=palette(num), linewidth=2, alpha=0.9, label=column)
	 
	# Add legend
	plt.legend(loc=0, ncol=1)
	 
	# Add titles
	plt.xlabel("Experience")
	plt.ylabel("Number of Bugs")
	
	plt.savefig(dir+"Figures&Tables/exp_line.png")

			
		
	





#figure1()
#figure2()
figure3()



















	
