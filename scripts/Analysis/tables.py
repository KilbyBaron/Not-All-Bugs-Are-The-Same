import os
import pandas as pd
import numpy as np
import re
import time
import datetime
import math


projects = ["accumulo","bookkeeper","camel","cassandra","cxf","derby","felix","hive","openjpa","pig","wicket"]

#Working directory
dir = os.getcwd()+"/../../"
os.chdir(dir)





def table_2():

	final = pd.read_csv(dir+"intermediate_files/avg_final.csv")
	targets = pd.read_csv(dir+"intermediate_files/target_releases.csv")
	
	
	t2 = pd.DataFrame(columns=['project','release','pre','post','files','buggy_files'])
	
	for p in projects:
		p_final = final.loc[(final['project'] == p)]
		minors = set(p_final['minor'])
		major = p_final.iloc[0]['major']
		for minor in minors:

			t2 = t2.append({
				'project':p,
				'release':str(major)+"."+str(minor)+".0",
				'pre':targets.loc[(targets['project'] == p) & (targets['minor'] == minor)].iloc[0]['pre'],
				'post':targets.loc[(targets['project'] == p) & (targets['minor'] == minor)].iloc[0]['post'],
				'files':p_final.loc[p_final['minor'] == minor]['filepath'].shape[0],
				'buggy_files':p_final.loc[(p_final['minor'] == minor)&(p_final['num_bugs']>0)].shape[0]
			},ignore_index=True)
		
	print(t2)














def table_1():

	#Make dictionary to store stats
	table1_dict = {}
	for p in projects+['total']:
		table1_dict[p] = {"bugs":0,"commits":0,"releases":0, "links":0}

	#Open up relevant CSVs
	jira = pd.read_csv(dir+"intermediate_files/jira_issues.csv")
	git = pd.read_csv(dir+"intermediate_files/github_commits.csv")
	links = pd.read_csv(dir+"intermediate_files/links.csv")
    
    #Calculate table stats and store them in a dict
	for p in projects:
		jira_issue_keys = set(jira.loc[(jira['Project key'] == p.upper()) & (jira['Issue Type'] == 'Bug')]['Issue key'])
		link_issue_keys = set(links.loc[links['project'] == p.upper()]['Issue key'])
    
		table1_dict[p]["bugs"] = len(jira_issue_keys)
		table1_dict[p]["commits"] = git.loc[git['project'] == p].shape[0]
		table1_dict[p]["releases"] = len(set(jira.loc[jira['Project key'] == p.upper()]['Affects Version/s']))
		table1_dict[p]["links"] = math.floor((len(link_issue_keys)/len(jira_issue_keys))*100)
		
		table1_dict['total']["bugs"] += table1_dict[p]["bugs"]
		table1_dict['total']["commits"] += table1_dict[p]["commits"]
		table1_dict['total']["releases"] += table1_dict[p]["releases"]
		table1_dict['total']["links"] += table1_dict[p]["links"]
		
	table1_dict['total']['links'] = math.floor(table1_dict['total']['links']/len(projects))
	

	#Read in a latex table and fill in the new statistics
	table1_tex = ""
	
	with open("scripts/Analysis/table1.txt", "r") as f:
		for line in f.readlines():
			for p in table1_dict:
				if line.lower().startswith(p):
					line = line.replace("n1n1",str(table1_dict[p]['bugs']))
					line = line.replace("n2n2",str(table1_dict[p]['commits']))
					line = line.replace("n3n3",str(table1_dict[p]['releases']))
					line = line.replace("n4n4",str(table1_dict[p]['links'])+"\%")
			
			table1_tex += line
	print(table1_tex)
	f = open('table1_tex.txt','w')
	f.write(table1_tex)
	f.close()	


table_2()

        


