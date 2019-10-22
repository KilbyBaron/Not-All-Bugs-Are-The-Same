import os
import pandas as pd
import numpy as np
import re
import time
import datetime
import math



"""

This script is used to make the tables for the paper. It outputs text files 
that contain latex code that can be pasted into overleaf.

"""




projects = ["accumulo","bookkeeper","camel","cassandra","cxf","derby","felix","hive","openjpa","pig","wicket"]

#Working directory
dir = os.getcwd()+"/../../"
os.chdir(dir)




def table_6():

	df = pd.read_csv(dir+"intermediate_files/t6_results.csv")

	#Read in a latex table and fill in the new statistics
	table6_tex = ""

	with open("scripts/Analysis/blank_tables/table6.txt", "r") as f:
		for line in f.readlines():
			if "insert_data" not in line:
				table6_tex += line

			else:
				print(1)
				
				for i,r in df.iterrows():
					if r['V1'] in projects:

						v3 = str(round(float(r['V3'])*100,1))
						v4 = str(round(float(r['V4'])*100,1))
						v5 = str(round(float(r['V5'])*100,1))
						v6 = str(round(float(r['V6'])*100,1))
						
						new_line = ""
						
						if r['V2'] == "X LOC":
							new_line += r['V1'].capitalize()

						new_line += "\t&\t"+r['V2']+"\t"
						new_line += "&\t"+v3+"\\%\t"
						new_line += "&\t"+v4+"\\%\t"
						new_line += "&\t"+v5+"\\%\t"
						new_line += "&\t"+v6+"\\%\t\\\\"
						
						if r['V2'] == "X churn":
							new_line += "\\hline"
						
						table6_tex += new_line+"\n"

		table6_tex += "\\hline"

	f = open('Figures&Tables/tables_latex/table6.txt','w')
	f.write(table6_tex)
	f.close()	




def table_5():
    
    df = pd.read_csv(dir+"intermediate_files/r2_results.csv")
    
    #Read in a latex table and fill in the new statistics
    table5_tex = ""

    with open("scripts/Analysis/blank_tables/table5.txt", "r") as f:
        for line in f.readlines():
            if "insert_data" not in line:
                table5_tex += line
                
            else:

                for i,r in df.iterrows():
                    
                    if r['V1'] in projects:
                    
                        v2 = str(round(float(r['V2'])*100))
                        v3 = str(round(float(r['V3'])*100))
                        v4 = str(round(float(r['V4'])*100))
                        v5 = str(round(float(r['V5'])*100))
                    
                        new_line = r['V1'].capitalize()+"\t"
                        new_line += "& & "+v2+"\\%\t"
                        new_line += "& & "+v3+"\\%\t["+str(round(float(r['V3'])/float(r['V2']),2))+"X]\t"
                        new_line += "&\t"+v4+"\\%\t["+str(round(float(r['V4'])/float(r['V2']),2))+"X]\t"
                        new_line += "&\t"+v5+"\\%\t["+str(round(float(r['V5'])/float(r['V2']),2))+"X]\t \\\\"
                        table5_tex += new_line+"\n"

                table5_tex += "\\hline"
                    
					

			       
    f = open('Figures&Tables/tables_latex/table5.txt','w')
    f.write(table5_tex)
    f.close()	



#This function is used to construct tables 3 and 4
#Since those tables require bug-level metrics, this function calculates the
#bfs, exp, and cost for each BFC, and returns them in lists
def get_bfs_exp_cost_lists(p_bfcs, p_numstats):
	
	bfs_list = []
	mean_exp_list = []
	cost_list = []
	

	for i,r in p_bfcs.iterrows():
		mean_exp=r['author_exp']
		
		bfs = 0
		bug_numstats = p_numstats.loc[p_numstats['hash'] == r['BFC_id']]
		for ni,nr in bug_numstats.iterrows():
			bfs += nr['la'] + nr['ld']
		cost = bfs*mean_exp
		
		
		bfs_list.append(bfs)
		mean_exp_list.append(mean_exp)
		cost_list.append(cost)
	return bfs_list, mean_exp_list, cost_list




#This function creates table 4 which contains RSDs
#Calculations are done at bug level not file level
def table_4():
    bfcs = pd.read_csv(dir+"intermediate_files/target_bfcs.csv")
    numstats = pd.read_csv(dir+"intermediate_files/numstats/all_numstats.csv")



    #Read in a latex table and fill in the new statistics
    table4_tex = ""

    with open("scripts/Analysis/blank_tables/table4.txt", "r") as f:
        for line in f.readlines():
            if "insert_data" not in line:
                table4_tex += line
            else:
                for project in projects:
                    p_bfcs = bfcs.loc[bfcs['project'] == project.upper()]
                    p_numstats = numstats.loc[numstats['project'] == project]

                    bfs_list, mean_exp_list, cost_list = get_bfs_exp_cost_lists(p_bfcs, p_numstats)

                    bfs_s = np.std(bfs_list)
                    exp_s = np.std(mean_exp_list)
                    cost_s = np.std(cost_list)
                    

                    bfs_rsd = round((100*bfs_s)/np.mean(bfs_list))
                    exp_rsd = round((100*exp_s)/np.mean(mean_exp_list))
                    cost_rsd = round((100*cost_s)/np.mean(cost_list))


                    new_line = project.capitalize()+"\t& &\t"
                    new_line += str(bfs_rsd)+"\\%\t& & &\t"
                    new_line += str(exp_rsd)+"\\%\t& & &\t"
                    new_line += str(cost_rsd)+"\\%\t& \\\\\n"
                    table4_tex += new_line
                    
                    
                table4_tex += "\\hline"
                    
					

			       
    print(table4_tex)
    f = open('Figures&Tables/tables_latex/table4.txt','w')
    f.write(table4_tex)
    f.close()	

	
	
	




#This function creates table 3 which contains Interquartile Ranges.
#Calculations are done at the bug level, not the file level.
def table_3():

	# Function to calculate IQR 
	def IQR(a, n):
		a.sort() 
		# Index of median of entire data 
		mid_index = median(a, 0, n) 
		# Median of first half 
		Q1 = a[median(a, 0, mid_index)] 
		# Median of second half 
		Q3 = a[median(a, mid_index + 1, n)] 
		# IQR calculation 
		return (Q3 - Q1)

	# Function to give index of the median 
	def median(a, l, r): 
		n = r - l + 1
		n = (n + 1) // 2 - 1
		return n + l 

	bfcs = pd.read_csv(dir+"intermediate_files/target_bfcs.csv")
	numstats = pd.read_csv(dir+"intermediate_files/numstats/all_numstats.csv")
	
	table3_tex = open("scripts/Analysis/blank_tables/table3.txt", "r").read()

	#print(final.columns.values)
	for project in projects:
	
		p_bfcs = bfcs.loc[bfcs['project'] == project.upper()]
		p_numstats = numstats.loc[numstats['project'] == project]
		
		bfs_list, mean_exp_list, cost_list = get_bfs_exp_cost_lists(p_bfcs, p_numstats)

		bfs_iqr = IQR(bfs_list,len(bfs_list))
		exp_iqr = IQR(mean_exp_list,len(mean_exp_list))
		cost_iqr = IQR(cost_list,len(cost_list))
		
		table3_tex = table3_tex.replace("bfs-"+project,str(bfs_iqr))
		table3_tex = table3_tex.replace("exp-"+project,str(exp_iqr))
		table3_tex = table3_tex.replace("cost-"+project,str(cost_iqr))

		
		
		
	f = open('Figures&Tables/tables_latex/table3.txt','w')
	f.write(table3_tex)
	f.close()	









#This function creates a dataframe to store the table information and then uses table2.txt
#to create the beginning of the table. The middle lines of latex are created without table2.txt.
#This is slightly different than table1 for no particular reason that I can remember.
def table_2():

	final = pd.read_csv(dir+"intermediate_files/final_dataset.csv")
	t_commits = pd.read_csv(dir+"intermediate_files/target_commits.csv")
	t_releases = pd.read_csv(dir+"intermediate_files/target_releases.csv")
	
	
	t2 = pd.DataFrame(columns=['project','release','pre','post','files','buggy_files'])
	
	
	#Start by making the table as a dataframe
	for p in projects:
		p_final = final.loc[(final['project'] == p)]
		minors = set(t_releases.loc[t_releases['project'] == p]['minor'])
		major = t_releases.loc[t_releases['project'] == p].iloc[0]['major']
		for minor in minors:
		    t2 = t2.append({
                'project':p,
                'release':str(major)+"."+str(minor)+".0",
                'pre':t_commits.loc[(t_commits['project'] == p) & (t_commits['minor'] == minor) & (t_commits['pre'] == 1)].shape[0],
                'post':t_commits.loc[(t_commits['project'] == p) & (t_commits['minor'] == minor) & (t_commits['post'] == 1)].shape[0],
                'files':p_final.loc[p_final['minor'] == minor]['filepath'].shape[0],
                'buggy_files':p_final.loc[(p_final['minor'] == minor)&(p_final['num_bugs']>0)].shape[0]
            },ignore_index=True)
		   
	
	#Read in a latex table and fill in the new statistics
	table2_tex = ""
	
	with open("scripts/Analysis/blank_tables/table2.txt", "r") as f:
		for line in f.readlines():
			if "insert_data" not in line:
				table2_tex += line
			else:
				counter = 1
				for i,r in t2.iterrows():
					new_line = ""
					if counter == 2:
						new_line += r['project'].capitalize()+"\t\t&"
					else:
						new_line += "\t\t&"

					new_line += str(r['release'])+"\t&\t"
					new_line += str(r['pre'])+"\t&\t"
					new_line += str(r['post'])+"\t&\t"
					new_line += str(r['files'])+"\t&\t"
					new_line += str(r['buggy_files'])

					new_line += "\t\t \\\\"

					if counter == 3:
						new_line += "\\hline"

					counter += 1
					if counter == 4:
						counter = 1
						
					table2_tex += new_line+"\n"
					

			       
	print(table2_tex)
	f = open('Figures&Tables/tables_latex/table2.txt','w')
	f.write(table2_tex)
	f.close()	




#This function puts all of the required data in a dictionary and then reads table1.txt 
#which contains special characters which can be replaced to create the completed latex code.
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
	
	with open("scripts/Analysis/blank_tables/table1.txt", "r") as f:
		for line in f.readlines():
			for p in table1_dict:
				if line.lower().startswith(p):
					line = line.replace("n1n1",str(table1_dict[p]['bugs']))
					line = line.replace("n2n2",str(table1_dict[p]['commits']))
					line = line.replace("n3n3",str(table1_dict[p]['releases']))
					line = line.replace("n4n4",str(table1_dict[p]['links'])+"\%")
			
			table1_tex += line
	print(table1_tex)
	f = open('Figures&Tables/tables_latex/table1.txt','w')
	f.write(table1_tex)
	f.close()	


table_6()

        


