
get.outcome = function(y, y.pred){
    flog.info("size: %s", length(y))
    return(ifelse(y==y.pred, ifelse(y=="buggy1", "TP", "TN"), ifelse(y=="buggy1", "FN", "FP")))    
}


setwd("~/Dropbox/phd-projects/project-misclassified-files/experiments-fn-files/")

# Load all train-test datasets
# ============================
list.ds = list.files("results-no-caret/predictions", full.names = T)
ds.all = c()
for(filename in list.ds){
    ds = read.csv(filename)
    ds.all = rbind(ds.all, ds)
}

ds.all = tbl_df(ds.all)

# Add outcome columns
# ===================
ds.new = ds.all %>%
    mutate(out.rf = get.outcome(buggy, rf), 
           out.glm = get.outcome(buggy, glm), 
           out.nb = get.outcome(buggy, nb), 
           out.rpart = get.outcome(buggy, rpart), 
           out.lda = get.outcome(buggy, lda), 
           out.qda = get.outcome(buggy, qda) )

# Calculate Majority-vote Outcome
# ===============================
Get.most.frequent = function(x){
    m = names(which.max(table(x)))
    return(m)
}

Get.num.fn = function(x){
    m = sum(x=='FN')
    return(m)
}

num.majority = ds.new %>% 
    select(out.rf, 
           out.glm, 
           out.nb, 
           out.rpart, 
           out.lda, 
           out.qda) %>% 
    apply(., 1, function(x) max(table(x)))

majority.vote = ds.new %>% 
    select(out.rf, 
           out.glm, 
           out.nb, 
           out.rpart, 
           out.lda, 
           out.qda) %>% 
    apply(., 1, Get.most.frequent)

num.fn = ds.new %>% 
    select(out.rf, 
           out.glm, 
           out.nb, 
           out.rpart, 
           out.lda, 
           out.qda) %>% 
    apply(., 1, Get.num.fn)



ds.new$majority.vote = majority.vote
ds.new$num.majority = num.majority
ds.new$num.fn = num.fn


#View(ds.new %>% filter(num.majority==3 & majority.vote == "FN"))

ds.summary = ds.new %>% 
    group_by(project, release_id) %>% 
    summarize(FN = sum(majority.vote=="FN"),
              TP = sum(majority.vote=="TP"),
              TN = sum(majority.vote=="TN"),
              FP = sum(majority.vote=="FP")) 
ds.summary

write.csv(ds.summary, "results-no-caret/FN-maj-vote-summary.csv", col.names = T, row.names=F, append = F )

# ================
ds.fn = ds.new %>% filter(buggy == 'buggy1' & majority.vote == "FN" & num.majority >= 3)
ds.fn.outs = ds.fn %>% select(out.rf, out.nb, out.glm, out.rpart, out.lda, out.qda)


# ================ Overlap among classifiers
# 3fn, 4fn 5fn and 6fn 
at.least.fn = ds.new %>% filter(out.rf=='FN' | out.nb=='FN' | out.glm== 'FN' | out.lda == 'FN' | out.qda== 'FN'| out.rpart=='FN')

ds.fn.overlap = at.least.fn  %>% group_by(project, release_id) %>% summarize(fn1=sum(num.fn==1), fn2=sum(num.fn==2), fn3=sum(num.fn==3), fn4=sum(num.fn==4), fn5=sum(num.fn==5), fn6=sum(num.fn==6))

write.csv(ds.fn.overlap, "results-no-caret/FNs-overlaps-summary.csv", col.names = T, row.names=F, append = F )

ds.new %>% filter(buggy=="buggy1")  %>% group_by(project, release_id) %>% summarize(fn1=sum(num.fn==1), fn2=sum(num.fn==2), fn3=sum(num.fn==3), fn4=sum(num.fn==4), fn5=sum(num.fn==5), fn6=sum(num.fn==6), fn0=sum(num.fn==0))


ds.overlap = ds.fn.overlap %>% ungroup() %>% summarize(fn3=sum(fn3), fn4=sum(fn4)*1.0, fn5=sum(fn5)*1.0, fn6=sum(fn6)*1.0, all=sum(fn3+fn4+fn5+fn6)) %>%
    mutate(fn3=100*fn3/all, fn4=100*fn4/all, fn5=100*fn5/all, fn6=100*fn6/all , all=NULL) %>% t(.)

colnames(ds.overlap) = c('Percentage')

ds.overlap = as.data.frame(ds.overlap)

ds.overlap$num.classifiers = row.names(ds.overlap)

ds.overlap


p=    ggplot(data=ds.overlap, aes(x=num.classifiers, y=Percentage)) +
    geom_bar(stat="identity", fill="#0072B2", alpha=.7)  +
    scale_x_discrete("", 
                    limit=c("fn3", "fn4", "fn5", "fn6" ),
                    labels=c('fn3'="Three\nML-techniques", 'fn4'="Four\nML-techniques", 'fn5'="Five\nML-techniques", 'fn6'="Six\nML-techniques")
    ) +
    ylab('Percentage of Agreement (%)') + xlab('') +
    theme(axis.text.x = element_text(vjust = 1, face='bold', size=12, color="black")) +
    theme(axis.text.y = element_text(vjust = 1, face='bold', size=11, color="black")) +
    theme(axis.title.y = element_text(vjust = 1, face='bold', size=13, color="black")) 

plot(p)
  

# ================ performance individual classifiers

ds.fn.tp.classifiers = cbind(ds.new %>% filter(buggy=="buggy1") %>% select(project, release_id, buggy, out=out.rf) %>% group_by(project, release_id) %>% summarize(fn=sum(out=='FN'), tp=sum(out=='TP')) %>% ungroup(),
      ds.new %>% filter(buggy=="buggy1") %>% select(project, release_id, buggy, out=out.nb) %>% group_by(project, release_id) %>% summarize(fn=sum(out=='FN'), tp=sum(out=='TP')) %>% ungroup() %>% select(fn,tp),
      ds.new %>% filter(buggy=="buggy1") %>% select(project, release_id, buggy, out=out.glm) %>% group_by(project, release_id) %>% summarize(fn=sum(out=='FN'), tp=sum(out=='TP')) %>% ungroup() %>% select(fn,tp),
      ds.new %>% filter(buggy=="buggy1") %>% select(project, release_id, buggy, out=out.lda) %>% group_by(project, release_id) %>% summarize(fn=sum(out=='FN'), tp=sum(out=='TP')) %>% ungroup() %>% select(fn,tp),
      ds.new %>% filter(buggy=="buggy1") %>% select(project, release_id, buggy, out=out.qda) %>% group_by(project, release_id) %>% summarize(fn=sum(out=='FN'), tp=sum(out=='TP')) %>% ungroup() %>% select(fn,tp),
      ds.new %>% filter(buggy=="buggy1") %>% select(project, release_id, buggy, out=out.rpart) %>% group_by(project, release_id) %>% summarize(fn=sum(out=='FN'), tp=sum(out=='TP')) %>% ungroup() %>% select(fn,tp))

colnames(ds.fn.tp.classifiers) = c('project', )

ds.fn.tp.classifiers = rbind(ds.new %>% filter(buggy=="buggy1") %>% select(project, release_id, buggy, out=out.rf) %>% group_by(project, release_id) %>% summarize(fn=sum(out=='FN'), tp=sum(out=='TP')) %>% ungroup() %>% mutate(model='rf'),
      ds.new %>% filter(buggy=="buggy1") %>% select(project, release_id, buggy, out=out.nb) %>% group_by(project, release_id) %>% summarize(fn=sum(out=='FN'), tp=sum(out=='TP')) %>% ungroup() %>% mutate(model='nb'),
      ds.new %>% filter(buggy=="buggy1") %>% select(project, release_id, buggy, out=out.glm) %>% group_by(project, release_id) %>% summarize(fn=sum(out=='FN'), tp=sum(out=='TP')) %>% ungroup() %>% mutate(model='glm'),
      ds.new %>% filter(buggy=="buggy1") %>% select(project, release_id, buggy, out=out.lda) %>% group_by(project, release_id) %>% summarize(fn=sum(out=='FN'), tp=sum(out=='TP')) %>% ungroup() %>%  mutate(model='lda'),
      ds.new %>% filter(buggy=="buggy1") %>% select(project, release_id, buggy, out=out.qda) %>% group_by(project, release_id) %>% summarize(fn=sum(out=='FN'), tp=sum(out=='TP')) %>% ungroup() %>% mutate(model='qda'),
      ds.new %>% filter(buggy=="buggy1") %>% select(project, release_id, buggy, out=out.rpart) %>% group_by(project, release_id) %>% summarize(fn=sum(out=='FN'), tp=sum(out=='TP')) %>% ungroup() %>% mutate(model='rpart'))

ds.fn.tp.classifiers

# =============== FN-rate by classifier
ds.fn.rate = ds.fn.tp.classifiers %>% mutate(fn.rate=100*fn/(fn+tp)) 


# =============== Boxplot FN-rate by classifier
library(ggplot2)

cbPalette <- c( "#009E73",  "#D55E00", "#0072B2" , "#CC79A7", "#E69F00", "#F0D4C2")

p.fn.classifier = ggplot(data=ds.fn.rate, aes(x=model, y=fn.rate, fill=model)) +
    geom_boxplot(alpha=.7) + 
    geom_point(position = position_jitter(width = 0.2,height = .1), alpha=.5, size=1.5) +
    scale_x_discrete(limits=c('nb', 'rpart', 'rf', 'glm', 'lda', 'qda'), labels=c('Naive\nBayes', 'CART', 'Rand\nForests', 'Logistic', 'LDA', 'QDA' )) +
    ylab('FN rate (%)') + xlab('') +
    scale_fill_manual(values=cbPalette, guide = FALSE) +
    theme(axis.text.x = element_text(vjust = 1, face='bold', size=12, color="black")) +
    theme(axis.text.y = element_text(vjust = 1, face='bold', size=11, color="black")) +
    theme(axis.title.y = element_text(vjust = 1, face='bold', size=13, color="black")) 

plot(p.fn.classifier)  


p.fn.classifier = ggplot(data = ds.fn.rate, aes(x = model, y = fn.rate)) + 
    geom_boxplot(aes(fill=factor(model))) + 
    geom_point(aes(color = factor(model))) 

  
    

View(ds.fn.tp.classifiers)

