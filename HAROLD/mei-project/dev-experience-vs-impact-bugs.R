suppressMessages(library(futile.logger))
library(argparse)
library(relaimpo)
library(pscl)
library(caret)
library(ROSE)
library(DMwR)
library(rpart)
library(C50)
library(randomForest)
library(klaR)
library(kernlab)
library(dplyr)
library(tidyr)
library(ggplot2)
# e1071


#get the name of the project from the file name
get_project = function(filename_coded_bug){
    filename_coded_bug = as.character(filename_coded_bug)
    splits = strsplit(filename_coded_bug, '--')
    splits = unlist(strsplit(filename_coded_bug, '--'))
    project = splits[1]
    project = gsub("\\d", "", project)
    return(project)
}

#get the issue of the bug from the file name
get_issue_id = function(filename_coded_bug){
    filename_coded_bug = as.character(filename_coded_bug)
    splits = unlist(strsplit(filename_coded_bug, '--'))
    issue_and_project = splits[2]
    splits_issue = unlist(strsplit(issue_and_project, '-'))
    issue_id = splits_issue[2]
    return(issue_id)
}


get_test_release = function(filename_coded_bug){
    filename_coded_bug = as.character(filename_coded_bug)
    splits = unlist(strsplit(filename_coded_bug, '--'))
    test_release = splits[3]
    test_release = as.numeric(gsub("test-release-", "", test_release))
    return(test_release)
}

get_impact = function(raw_impacts){
    n = length(raw_impacts)
    impacts = character(n)
    for(idx in 1:n){
        impact = raw_impacts[idx]
        if(impact == 'Hang'){
            impacts[idx] = 'Hang'
        }
        if(impact == 'Crash'){
            impacts[idx] = 'Crash'
        }
        if(impact == 'Corrupt'){
            impacts[idx] = 'Corrupt'
        }
        if(impact == 'Perf Degradation'){
            impacts[idx] = 'Perf'
        }
        if(impact == 'Incorrect Functionality (Func)'){
            impacts[idx] = 'Incorrect'
        }
        if(impact == 'Other'){
            impacts[idx] = 'Other'
        }
    }
    return(impacts)
}

get_component = function(raw_components){
    n = length(raw_components)
    components = character(n)
    for(idx in 1:n){
        component = raw_components[idx]
        if(component == 'Core'){
            components[idx] = 'Core'
        }
        if(component == 'GUI'){
            components[idx] = 'UI'
        }
        if(component == 'I/O'){
            components[idx] = 'I/O'
        }
        if(component == 'Network'){
            components[idx] = 'Network'
        }
    }
    return(components)
}

get_root_cause = function(causes, sub_causes){
    n = length(causes)
    root_causes = character(n)
    for(idx in 1:n){
        cause = causes[idx]
        sub_cause = sub_causes[idx]
        root_causes[idx] = ""
        if (cause == 'CON' ){
            root_causes[idx] = "Con"
        }else{
            if(cause == 'MEM'){
                root_causes[idx] = "Mem"
            }
            if(sub_cause == 'SEM_Typo'){
                root_causes[idx] = "Typo"
            }
            if(sub_cause == 'SEM_Other (FuncImp)'){
                root_causes[idx] = "FuncImpl"
            }
            if(sub_cause == 'SEM_MissCases'){
                root_causes[idx] = "MissC"
            }
            if(sub_cause == 'SEM_CtrlFlow'){
                root_causes[idx] = "CtrlFlow"
            }
            if(sub_cause == 'SEM_Exception'){
                root_causes[idx] = "Except"
            }
            if(sub_cause == 'SEM_CornerCases'){
                root_causes[idx] = "CornerC"
            }
            if(sub_cause == 'SEM_Process'){
                root_causes[idx] = "Process"
            }
            if(sub_cause == 'SEM_MissFeatures'){
                root_causes[idx] = "MissF"
            }
        }
    }
    return(root_causes)
}

# Remove invalid-bugs and include only the ones
# that have cause, impact and component
get_valid_coded_bugs <- function(ds_bugs){
    # Remove invalid-bugs
    valid_coded_bugs = ds_bugs[ds_bugs$INVALID == 0 | ds_bugs$INVALID == "", ]
    valid_coded_bugs = valid_coded_bugs[valid_coded_bugs$CAUSE != 0 & valid_coded_bugs$CAUSE != "", ]
    valid_coded_bugs = valid_coded_bugs[valid_coded_bugs$IMPACT != 0 & valid_coded_bugs$IMPACT != "", ]
    valid_coded_bugs = valid_coded_bugs[valid_coded_bugs$COMPONENT != 0 & valid_coded_bugs$COMPONENT != "", ]
    flog.debug('Num-valid-bugs: %s', nrow(valid_coded_bugs))
    
    # Redine root-cause
    #valid_coded_bugs$root_cause = get_root_cause(valid_coded_bugs$CAUSE, valid_coded_bugs$CAUSE_SUB)
    return(valid_coded_bugs)
}

#get the fixing_cost per issue
get_fixing_cost = function(churn, experience){
  fixing_cost = churn * experience
  return(fixing_cost)
}

# QDA-file for the TP-bugs
ds_qda_tp_bugs <- read.csv("~/Desktop/phd-projects/project-misclassified-files/dataset/sample-issues/qualitative-analysis-qda/qda-tp-bugs.csv")
ds_qda_tp_bugs$type_bug = 'TP Bugs'

# QDA-file for the FN-bugs
ds_qda_fn_bugs <- read.csv("~/Desktop/phd-projects/project-misclassified-files/dataset/sample-issues/qualitative-analysis-qda/qda-fn-bugs.csv")
ds_qda_fn_bugs$type_bug = 'FN Bugs'

# Join both (TP-FP bugs) csv. 
ds_qda_both_bugs = rbind(ds_qda_tp_bugs, ds_qda_fn_bugs) #Joining two datasets vertically (must have same variables)
#Adding the name of the project into a new column to the dataset. We use get project that extracts from the column file of the new dataset the name 
ds_qda_both_bugs$project = lapply(ds_qda_both_bugs$FILE, get_project) #the name of the project in each element of the list ds_qda_both_bugs$FILE
#Adding the issue of the bug into a new column to the dataset. We use get_issue_id to extract from the column file of the issue 
ds_qda_both_bugs$issue_id = lapply(ds_qda_both_bugs$FILE, get_issue_id) #the issue of the bug in each element of the list ds_qda_both_bugs$FILE
#Adding the root_cause of the bug into a new column to the dataset. We use get_root_cause function
ds_qda_both_bugs$root_cause = get_root_cause(ds_qda_both_bugs$CAUSE, ds_qda_both_bugs$CAUSE_SUB)
#Adding the impact of the bug into a new column to the dataset. We use get_impact function
ds_qda_both_bugs$impact = get_impact(ds_qda_both_bugs$IMPACT)
#Adding the component of the bug into a new column to the dataset. We use get_component function
ds_qda_both_bugs$component = get_component(ds_qda_both_bugs$COMPONENT)

#Saving the new csv.
setwd("~/Desktop/phd-projects/mei-project/")
valid_coded_bugs = get_valid_coded_bugs(ds_qda_both_bugs)
ds_qda_both_TP_TN = valid_coded_bugs
ds_qda_both_TP_TN <- apply(ds_qda_both_TP_TN,2,as.character)
write.csv(ds_qda_both_TP_TN, file="ds_qda_both_TP_TN.csv" )


ds.coded.bugs = tbl_df(valid_coded_bugs) #Creating a dataframe table
#ds.coded.bugs$issue_id = as.character(ds.coded.bugs$issue_id) 
ds.coded.bugs$project = as.character(ds.coded.bugs$project)
ds.coded.bugs
View(ds.coded.bugs)

#Creating a dataframe with the columns issue_id, project, IMPACT, root_cause from table ds.coded.bugs
ds.coded.bugs.impact = ds.coded.bugs %>% select(issue_id, project, IMPACT, root_cause)

#Adding column impactfulness to table ds.coded.bugs.impact
# Where the value will be 'impactful' whether the IMAPCT value is 'Corrupt' or 'Perf Degradation'. Other cases the value will be 'non-impactful'
ds.coded.bugs.impact$impactfulness = ifelse(ds.coded.bugs.impact$IMPACT=='Corrupt' | ds.coded.bugs.impact$IMPACT == 'Perf Degradation', 'impactful', 'non-impactful')


plot_impact = ggplot(data=ds.coded.bugs.impact, aes(x=IMPACT)) +
    geom_bar(aes(y = (..count..)/sum(..count..)*100), fill="#0072B2", alpha=.9) + 
    scale_x_discrete("\nImpact", 
                     limit=c( "Corrupt", "Perf Degradation", "Hang", "Crash", "Incorrect Functionality (Func)", "Other"),
                     labels=c("Incorrect Functionality (Func)" = "Incorrect", "Perf Degradation" = "Perf")
    ) + 
    ggtitle(paste("", '', sep="\n")) + 
    scale_fill_brewer() +
    labs(y='Percentage of bugs (%)')+
    theme(axis.text.x = element_text(vjust = 1, face='bold', size=12, color="black")) +
    theme(axis.text.y = element_text(vjust = 1, face='bold', size=11, color="black")) +
    theme(axis.title.y = element_text(vjust = 1, face='bold', size=12, color="black")) +
    theme(axis.title.x = element_text(vjust = 1, face='bold', size=14, color="black")) #+
#    scale_fill_manual(values=cbPalette, guide = FALSE) 

plot(plot_impact)

# ========================
#list.ds.bug.exp = Sys.glob("/Users/hv1710/Documents/workspaces/workspace-project-with-mei/code-repositories/*/results/master-branch/0-second-new-dataset-issues-commits-removing-weird-files.csv")

#ds.bug.exp = c()
#for(filename in list.ds.bug.exp){
#    ds = read.csv(filename)
#    ds.bug.exp = rbind(ds.bug.exp, ds)
#}
#ds.bug.exp = tbl_df(ds.bug.exp)
#ds.bug.exp$issue_id = as.character(ds.bug.exp$issue_id)
#ds.bug.exp

#ds.bug.metrics = ds.bug.exp %>% select(issue_id, priority, fixing_time, total_churn, mean_experience) 


# ======================= Join bug.metrics and bug.impact
#ds.join = inner_join(ds.coded.bugs.impact, ds.bug.metrics) 
# ds.join <- read.csv("~/Downloads/phd-projects/mei-project/")
#setwd("~/Downloads/phd-projects/mei-project/")
#write.csv(ds.join, "ds-dev-experience-vs-impact.csv", col.names = T, row.names=F, append = F )


# ====================== Load Join
ds.join = read.csv('~/Desktop/phd-projects/mei-project/ds-dev-experience-vs-impact.csv')
ds.join = tbl_df(ds.join)

# Split the bugs into impactful and non-impactful bugs
ds.join$impactfulness = ifelse(ds.join$impact=='Corrupt' | ds.join$impact == 'Perf Degradation', 'impactful', 'non-impactful')



cbPalette <- c( "#009E73",  "#D55E00", "#0072B2" , "#CC79A7", "#E69F00", "#F0D4C2")

#If experience is 0, we are adding 1 as experience to can compute metrics
ds.join$mean_experience2 = ifelse(ds.join$mean_experience== 0, 1.0, ds.join$mean_experience)

#Adding the fixing cost of the bug into a new column to the dataset. We use get_fixing_cost function
ds.join$fixing_cost = get_fixing_cost(ds.join$total_churn, ds.join$mean_experience2)

p.fn.classifier = ggplot(data=ds.join %>% filter(impact!='Other'), 
                         aes(x=impact, y=mean_experience2, fill=impactfulness)) +
    geom_boxplot(alpha=.7) + 
    #geom_point(position = position_jitter(width = 0.2,height = .1), alpha=.5, size=1.5) +
    #scale_x_discrete(limits=c('nb', 'rpart', 'rf', 'glm', 'lda', 'qda'), labels=c('Naive\nBayes', 'CART', 'Rand\nForests', 'Logistic', 'LDA', 'QDA' )) +
    #ylab('FN rate (%)') + xlab('') +
    scale_fill_manual(values=cbPalette, labels=c("Impactful  ", "Non-impactful  ")) +
    theme(axis.text.x = element_text(vjust = 1, face='bold', size=12, color="black")) +
    theme(axis.text.y = element_text(vjust = 1, face='bold', size=11, color="black")) +
    theme(axis.title.y = element_text(vjust = 1, face='bold', size=13, color="black")) +
    scale_x_discrete("", 
                     limit=c( "Corrupt", "Perf Degradation", "Hang", "Crash", "Incorrect Functionality (Func)"),
                     labels=c("Incorrect Functionality (Func)" = "Incorrect", "Perf Degradation" = "Perf")
    )+ #scale_y_continuous(limits = c(0,650))+
    guides(fill=guide_legend(title=NULL))+
    theme(legend.text = element_text(size = 14,face='bold'))+
    theme(legend.key.size=unit(1.3,"cm"),legend.position="bottom", 
          legend.background = element_rect(fill  ="white"),
          legend.key = element_rect(fill = 'white')
          )+
    labs(y="Developer Experience") 

    #coord_trans(y="log10")

plot(p.fn.classifier)  

ds.impactfulness = ds.join %>% filter(impact!='Other')

impactful= ds.impactfulness %>% filter(impactfulness=='impactful')
impactful = impactful$mean_experience
non.impactful = ds.impactfulness %>% filter(impactfulness=='non-impactful') 
non.impactful = non.impactful$mean_experience

wilcox.test(impactful, non.impactful, correct = FALSE)


# =======
p.impactfulness = ggplot(data=ds.join %>% filter(impact != 'Other'), aes(x=impactfulness, y=mean_experience2, fill=impactfulness)) +
    geom_boxplot(alpha=.7) + 
    geom_point(position = position_jitter(width = 0.2,height = .1), alpha=.5, size=1.5) +
    #scale_x_discrete(limits=c('nb', 'rpart', 'rf', 'glm', 'lda', 'qda'), labels=c('Naive\nBayes', 'CART', 'Rand\nForests', 'Logistic', 'LDA', 'QDA' )) +
    #ylab('FN rate (%)') + xlab('') +
    scale_fill_manual(values=cbPalette, guide = FALSE) +
    theme(axis.text.x = element_text(vjust = 1, face='bold', size=12, color="black")) +
    theme(axis.text.y = element_text(vjust = 1, face='bold', size=11, color="black")) +
    theme(axis.title.y = element_text(vjust = 1, face='bold', size=13, color="black")) 
plot(p.impactfulness)


ds.join %>% group_by(impact) %>% summarize()


#----------------
p.devExp_project = ggplot(ds.join, aes(x=project, y=mean_experience2)) + 
  geom_boxplot(fill="white", alpha=0.8) + 
  theme(axis.text.x = element_text(vjust = 1, face='bold', size=12, color="black")) +
  theme(axis.text.y = element_text(vjust = 1, face='bold', size=11, color="black")) +
  theme(axis.title.y = element_text(vjust = 1, face='bold', size=13, color="black")) +
  scale_x_discrete("", 
                     limit=c( "accumulo", "bookkeeper", "camel", "cassandra", "CXF", "derby","felix","hive","openjpa", "pig","wicket"),
            labels=c("accumulo"= "Accumulo", "bookkeeper"="Bookkeeper", "camel"= "Camel", "cassandra"="Cassandra",
            "derby"="Derby","felix"="Felix","hive"="Hive","openjpa"="Openjpa", "pig"="Pig","wicket"="Wicket")
    ) + scale_y_log10() +
  ylab("Developer Experience")

plot(p.devExp_project)  

accumulo_p= ds.join %>% filter(project == 'accumulo')
accumulo <- c(accumulo_mean_experience= IQR(accumulo_p$mean_experience2),
              accumulo_bug_fix= IQR(accumulo_p$total_churn),
              accumulo_fixing_cost= IQR(accumulo_p$fixing_cost)
              )



bookkeeper_p= ds.join %>% filter(project == 'bookkeeper')
bookkeeper <- c(bookkeeper_mean_experience= IQR(bookkeeper_p$mean_experience2), 
                bookkeeper_bug_fix= IQR(bookkeeper_p$total_churn),
                bookkeeper_fixing_cost= IQR(bookkeeper_p$fixing_cost)
                )

pig_p= ds.join %>% filter(project == 'pig')
pig <- c(pig_mean_experience= IQR(pig_p$mean_experience2), 
         pig_bug_fix= IQR(pig_p$total_churn),
         pig_fixing_cost= IQR(pig_p$fixing_cost)
         )

camel_p= ds.join %>% filter(project == 'camel')
camel <- c(camel_mean_experience= IQR(camel_p$mean_experience2), 
           camel_bug_fix= IQR(camel_p$total_churn),
           camel_fixing_cost= IQR(camel_p$fixing_cost))

cassandra_p= ds.join %>% filter(project == 'cassandra')
cassandra<- c(cassandra_mean_experience= IQR(cassandra_p$mean_experience2), 
              cassandra_bug_fix= IQR(cassandra_p$total_churn),
              cassandra_fixing_cost= IQR(cassandra_p$fixing_cost)
              )

CXF_p= ds.join %>% filter(project == 'CXF')
CXF<- c(CXF_mean_experience= IQR(CXF_p$mean_experience2) ,
        CXF_bug_fix= IQR(CXF_p$total_churn),
        CXF_fixing_cost= IQR(CXF_p$fixing_cost)
        )

derby_p= ds.join %>% filter(project == 'derby')
derby<- c(derby_mean_experience= IQR(derby_p$mean_experience2),
          derby_bug_fix= IQR(derby_p$total_churn),
          derby_fixing_cost= IQR(derby_p$fixing_cost)
          )

felix_p= ds.join %>% filter(project == 'felix')
felix<- c(felix_mean_experience= IQR(felix_p$mean_experience2),
          felix_bug_fix= IQR(felix_p$total_churn),
          felix_fixing_cost= IQR(felix_p$fixing_cost)
          )

hive_p= ds.join %>% filter(project == 'hive')
hive <- c(hive_mean_experience= IQR(hive_p$mean_experience2),
          hive_bug_fix= IQR(hive_p$total_churn),
          hive_fixing_cost= IQR(hive_p$fixing_cost)
          )

openjpa_p= ds.join %>% filter(project == 'openjpa')
openjpa <- c(openjpa_mean_experience= IQR(openjpa_p$mean_experience2),
             openjpa_bug_fix= IQR(openjpa_p$total_churn),
             openjpa_fixing_cost= IQR(openjpa_p$fixing_cost)
            )

wicket_p= ds.join %>% filter(project == 'wicket')
wicket <- c(wicket_mean_experience= IQR(wicket_p$mean_experience2), 
            wicket_bug_fix= IQR(wicket_p$total_churn),
            wicket_fixing_cost= IQR(wicket_p$fixing_cost)
            )

projectsIQR <- data.frame(accumulo, bookkeeper,camel,cassandra,CXF,derby,felix,hive,openjpa,pig,wicket)

# -------------- Bug fix size per project --------
# ------------------------------------------------

p.BugFix_size_project = ggplot(ds.join, aes(x=project, y=total_churn)) + 
  geom_boxplot(fill="white", alpha=0.8) + 
  theme(axis.text.x = element_text(vjust = 1, face='bold', size=12, color="black")) +
  theme(axis.text.y = element_text(vjust = 1, face='bold', size=11, color="black")) +
  theme(axis.title.y = element_text(vjust = 1, face='bold', size=13, color="black")) +
  scale_x_discrete("", 
                   limit=c( "accumulo", "bookkeeper", "camel", "cassandra", "CXF", "derby","felix","hive","openjpa", "pig","wicket"),
                   labels=c("accumulo"= "Accumulo", "bookkeeper"="Bookkeeper", "camel"= "Camel", "cassandra"="Cassandra",
                            "derby"="Derby","felix"="Felix","hive"="Hive","openjpa"="Openjpa", "pig"="Pig","wicket"="Wicket")
  ) + scale_y_log10() +
  ylab("Bug-Fix Size")

plot(p.BugFix_size_project)  


# -------------- Bug fix size per project --------
# ------------------------------------------------

p.Fixing_Cost_project = ggplot(ds.join, aes(x=project, y=fixing_cost)) + 
  geom_boxplot(fill="white", alpha=0.8) + 
  theme(axis.text.x = element_text(vjust = 1, face='bold', size=12, color="black")) +
  theme(axis.text.y = element_text(vjust = 1, face='bold', size=11, color="black")) +
  theme(axis.title.y = element_text(vjust = 1, face='bold', size=13, color="black")) +
  scale_x_discrete("", 
                   limit=c( "accumulo", "bookkeeper", "camel", "cassandra", "CXF", "derby","felix","hive","openjpa", "pig","wicket"),
                   labels=c("accumulo"= "Accumulo", "bookkeeper"="Bookkeeper", "camel"= "Camel", "cassandra"="Cassandra",
                            "derby"="Derby","felix"="Felix","hive"="Hive","openjpa"="Openjpa", "pig"="Pig","wicket"="Wicket")
  ) + scale_y_log10() +
  ylab("Fixing Cost")

plot(p.Fixing_Cost_project)  



# -------------- devExp per priority --------
# ------------------------------------------------

p.DevExp_Priority = ggplot(ds.join, aes(x=priority, y=mean_experience2)) + 
  geom_boxplot(fill="white", alpha=0.8) + 
  theme(axis.text.x = element_text(vjust = 1, face='bold', size=12, color="black")) +
  theme(axis.text.y = element_text(vjust = 1, face='bold', size=11, color="black")) +
  theme(axis.title.y = element_text(vjust = 1, face='bold', size=13, color="black")) +
  scale_y_log10() +
  ylab("Dev Experience")

plot(p.DevExp_Priority) 

# -------------- BugSize per priority --------
# ------------------------------------------------

p.BugSize_Priority = ggplot(ds.join, aes(x=priority, y=total_churn)) + 
  geom_boxplot(fill="white", alpha=0.8) + 
  theme(axis.text.x = element_text(vjust = 1, face='bold', size=12, color="black")) +
  theme(axis.text.y = element_text(vjust = 1, face='bold', size=11, color="black")) +
  theme(axis.title.y = element_text(vjust = 1, face='bold', size=13, color="black")) +
  scale_y_log10() +
  ylab("Dev Experience")

plot(p.BugSize_Priority) 


# -------------- Fixing Cost per priority --------
# ------------------------------------------------

p.Fixing_Cost_Priority = ggplot(ds.join, aes(x=priority, y=fixing_cost)) + 
  geom_boxplot(fill="white", alpha=0.8) + 
  theme(axis.text.x = element_text(vjust = 1, face='bold', size=12, color="black")) +
  theme(axis.text.y = element_text(vjust = 1, face='bold', size=11, color="black")) +
  theme(axis.title.y = element_text(vjust = 1, face='bold', size=13, color="black")) +
  scale_y_log10() +
  ylab("Fixing Cost")

plot(p.Fixing_Cost_Priority) 




# -------------- devExp per Impact --------
# ------------------------------------------------

p.DevExp_Impact = ggplot(ds.join, aes(x=impact, y=mean_experience2)) + 
  geom_boxplot(fill="white", alpha=0.8) + 
  theme(axis.text.x = element_text(vjust = 1, face='bold', size=12, color="black")) +
  theme(axis.text.y = element_text(vjust = 1, face='bold', size=11, color="black")) +
  theme(axis.title.y = element_text(vjust = 1, face='bold', size=13, color="black")) +
  scale_x_discrete("", 
                   limit=c( "Corrupt", "Perf Degradation", "Hang", "Crash", "Incorrect Functionality (Func)"),
                   labels=c("Incorrect Functionality (Func)" = "Incorrect", "Perf Degradation" = "Perf")
  )+
  scale_y_log10() +
  ylab("DevExp_Impact")

plot(p.DevExp_Priority) 


# -------------- BugSize per Impact --------
# ------------------------------------------------

p.BugSize_Impact = ggplot(ds.join, aes(x=impact, y=total_churn)) + 
  geom_boxplot(fill="white", alpha=0.8) + 
  theme(axis.text.x = element_text(vjust = 1, face='bold', size=12, color="black")) +
  theme(axis.text.y = element_text(vjust = 1, face='bold', size=11, color="black")) +
  theme(axis.title.y = element_text(vjust = 1, face='bold', size=13, color="black")) +
  scale_x_discrete("", 
                   limit=c( "Corrupt", "Perf Degradation", "Hang", "Crash", "Incorrect Functionality (Func)"),
                   labels=c("Incorrect Functionality (Func)" = "Incorrect", "Perf Degradation" = "Perf")
  )+
  scale_y_log10() +
  ylab("Bug-Fixing Size")

plot(p.BugSize_Impact) 

# -------------- FixingCost per Impact --------
# ------------------------------------------------

p.Fixing_Cost_Impact = ggplot(ds.join, aes(x=impact, y=fixing_cost)) + 
  geom_boxplot(fill="white", alpha=0.8) + 
  theme(axis.text.x = element_text(vjust = 1, face='bold', size=12, color="black")) +
  theme(axis.text.y = element_text(vjust = 1, face='bold', size=11, color="black")) +
  theme(axis.title.y = element_text(vjust = 1, face='bold', size=13, color="black")) +
  scale_x_discrete("", 
                   limit=c( "Corrupt", "Perf Degradation", "Hang", "Crash", "Incorrect Functionality (Func)"),
                   labels=c("Incorrect Functionality (Func)" = "Incorrect", "Perf Degradation" = "Perf")
  )+
  scale_y_log10() +
  ylab("Fixing_cost Size")

plot(p.Fixing_Cost_Impact) 
