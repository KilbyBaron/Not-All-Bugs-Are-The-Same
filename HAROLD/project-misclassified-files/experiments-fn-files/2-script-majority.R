
get.outcome = function(y, y.pred){
    flog.info("size: %s", length(y))
    return(ifelse(y==y.pred, ifelse(y=="buggy1", "TP", "TN"), ifelse(y=="buggy1", "FN", "FP")))    
}


setwd("~/Dropbox/phd-projects/project-misclassified-files/experiments-fn-files/")

# Load all train-test datasets
# ============================
list.ds = list.files("results/predictions", full.names = T)
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

write.csv(ds.summary, "results/FN-maj-vote-summary.csv", col.names = T, row.names=F, append = F )

# ================
ds.fn = ds.new %>% filter(buggy == 'buggy1' & majority.vote == "FN" & num.majority >= 3)
ds.fn.outs = ds.fn %>% select(out.rf, out.nb, out.glm, out.rpart, out.lda, out.qda)


# ================ Overlap among classifiers
# 3fn, 4fn 5fn and 6fn 
at.least.fn = ds.new %>% filter(out.rf=='FN' | out.nb=='FN' | out.glm== 'FN' | out.lda == 'FN' | out.qda== 'FN'| out.rpart=='FN')

ds.fn.overlap = at.least.fn  %>% group_by(project, release_id) %>% summarize(fn1=sum(num.fn==1), fn2=sum(num.fn==2), fn3=sum(num.fn==3), fn4=sum(num.fn==4), fn5=sum(num.fn==5), fn6=sum(num.fn==6))

write.csv(ds.fn.overlap, "results/FNs-overlaps-summary.csv", col.names = T, row.names=F, append = F )

ds.new %>% filter(buggy=="buggy1")  %>% group_by(project, release_id) %>% summarize(fn1=sum(num.fn==1), fn2=sum(num.fn==2), fn3=sum(num.fn==3), fn4=sum(num.fn==4), fn5=sum(num.fn==5), fn6=sum(num.fn==6), fn0=sum(num.fn==0))



# ================ performance individual classifiers
