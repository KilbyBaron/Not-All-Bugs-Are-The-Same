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
# e1071

SMOTE.for.buggy = function (x, y) {
    # Customized version of SMOTE. The method tries 
    # to preserve the original size of the dataset.
    dat <- if (is.data.frame(x)) x else as.data.frame(x)
    dat$.y <- y
    
    # Get the current size for each class
    n.data = length(y)
    n.buggy1 = length(y[y=='buggy1'])
    n.buggy0 = length(y[y=='buggy0'])
    
    # Get the desire sizes for each class
    percent.buggy1 = .3
    new.n.buggy1 = percent.buggy1 * n.data 
    new.n.buggy0 = (1 - percent.buggy1) * n.data 
    
    # Get the over and under to achieve the desired sizes
    over.value = 100*(new.n.buggy1 - n.buggy1)/n.buggy1
    under.value = 100*new.n.buggy0/(new.n.buggy1 - n.buggy1)
    
    dat <- SMOTE(.y ~ ., data = dat, perc.over = over.value, perc.under = under.value)
    list(x = dat[, !grepl(".y", colnames(dat), fixed = TRUE)],  y = dat$.y)
}

smote.policy <- list(name = "SMOTE with better sampling!", func = SMOTE.for.buggy, first = TRUE)


# Define the controls for trainControl
# ===================================
K.FOLDS = 10
NUM.REPEATED.CV = 100
ctrl.repeatedcv <- trainControl(method = "repeatedcv", 
                                repeats = NUM.REPEATED.CV, 
                                number = K.FOLDS,
                                classProbs = TRUE,
                                summaryFunction = twoClassSummary,   
                                preProcOptions = list(thresh = .8),  # For PCA
                                sampling = smote.policy,             
                                verboseIter=FALSE)

ctrl.cv <- trainControl(method = "cv", 
                        number = K.FOLDS,
                        classProbs = TRUE,
                        summaryFunction = twoClassSummary,
                        preProcOptions = list(thresh = .8),
                        sampling = smote.policy, 
                        verboseIter=FALSE)

ctrl.oob <- trainControl(method = "oob", 
                         repeats = NUM.REPEATED.CV, 
                         number = K.FOLDS,
                         classProbs = TRUE,
                         summaryFunction = twoClassSummary,
                         preProcOptions = list(thresh = .8),
                         sampling = smote.policy, 
                         verboseIter=FALSE)


FILE.TRAD.PERFORMANCE = "results/traditional.performance.csv"
Get.traditional.Performance = function(best.model, ds.testing, save.flag=FALSE){
    # Compute:
    # Precision, Recall, F, AUC, FN-rate, TP, FN, TN FP
    project = as.character(ds.testing$project)[1]
    release.train = ds.testing$release_id[1] - 1
    release.test = ds.testing$release_id[1]
    
    flog.info("Get.traditional.Performance - %s - predict-raw", best.model$method)
    pred = predict(best.model, ds.testing %>% select(-buggy), type="raw")
    
    flog.info("Get.traditional.Performance - %s - conf.mtx", best.model$method)
    conf.mtx= confusionMatrix(pred, ds.testing$buggy)$table
    TP = conf.mtx[1,1]
    FN = conf.mtx[2,1]
    TN = conf.mtx[2,2]
    FP = conf.mtx[1,2]
    
    precision = posPredValue(pred, ds.testing$buggy)
    recall = sensitivity(pred, ds.testing$buggy)
    Fmeasure = (2 * precision * recall) / (precision + recall)
    FNrate = 1 - recall
    
    # AUC in the testing
    flog.info("Get.traditional.Performance - %s - predict-prob", best.model$method)
    pred.prob <- predict(best.model, ds.testing, type="prob")
    pred.prob = pred.prob$buggy1
    
    flog.info("Get.traditional.Performance - %s - predict-ROC", best.model$method)
    library(pROC)
    roc.obj <- roc(ds.testing$buggy, pred.prob)
    auc.value = roc.obj$auc
    
    perf.metrics = cbind(precision=precision, recall=recall, Fmeasure=Fmeasure, 
                         AUC=auc.value, FNrate=FNrate, FN=FN, TP=TP, TN=TN, FP=FP)
    perf.metrics = as.data.frame(perf.metrics)
    perf.metrics$model = best.model$method
    
    # Save the results
    # ================
    if(save.flag){
        flog.info("Get.traditional.Performance - %s - Save-metrics", best.model$method)
        perf.copy = perf.metrics
        perf.copy$project = project
        perf.copy$release.train = release.train
        perf.copy$release.test = release.test
        filename = FILE.TRAD.PERFORMANCE
        if(!file.exists(filename)){
            dir.create(dirname(filename), recursive = T)
            write.table(perf.copy, filename, sep = ",", col.names = T, append = T, row.names = F)        
        }else{
            write.table(perf.copy, filename, sep = ",", col.names = F, append = T, row.names = F)
        }   
    }
    return(perf.metrics)
}


PREDICTIONS.DIR = "results/predictions"
incremental.prediction = function(best.model, data.test){
    project = as.character(data.test$project)[1]
    release.train = data.test$release_id[1] - 1
    release.test = data.test$release_id[1]
    
    # Sort data.test based on the path
    data.test = data.test %>% arrange(path)
    
    # Construct the filename to save the test
    # e.i., results/predictions/accumulo-train0-test1.csv
    filename = sprintf("%s/%s-train%d-test%d.csv", PREDICTIONS.DIR, 
                       project, release.train, release.test)
    if(!file.exists(filename)){
        dir.create(dirname(filename), recursive = T)
        flog.info("incremental.predict - %s - Initial-save", best.model$method)
        write.table(data.test, filename, sep = ",", col.names = T, append = F, row.names = F) 
    }
    
    # Load the stored.data.test 
    s.data.test = read.csv(filename) %>% tbl_dt(.) %>% arrange(path)
    
    # Verify if they are the same 
    n.s = nrow(s.data.test)
    n.t = nrow(data.test)
    if(n.s != n.t | sum(s.data.test$buggy != data.test$buggy) != 0){
        flog.error("incremental.predict - Error")
        flog.error("%s - r-train:%s - r-test:%s - ns:%s - nt:%s", 
                   project, release.train, release.test, n.s, n.t)
        file.dt = ".data-test-error.csv"
        file.sdt = ".stored-data-test-error.csv"
        write.table(data.test, file.dt , sep = ",", col.names = T, append = F, row.names = F) 
        write.table(s.data.test, file.sdt, sep = ",",col.names = T,append = F, row.names = F) 
        stop("Error in incremental.prediction")
    }
    
    # Evaluate best.model on s.data.test (or data.test)
    flog.info("incremental.predict - %s - Predict", best.model$method)
    pred = predict(best.model, data.test %>% select(-buggy), type="raw")
    s.data.test[[best.model$method]] = pred
    
    flog.info("incremental.predict - %s - Save-prediction", best.model$method)
    write.table(s.data.test, filename, sep = ",", col.names = T, append = F, row.names = F)
}


setwd("~/Dropbox/phd-projects/project-misclassified-files/experiments-fn-files/")


flog.appender(appender.tee("fn.experiments.log"))
flog.threshold(DEBUG)

filename.ds = "dataset-all-projects.csv"
ds = read.csv(filename.ds)

# Create the buggy-column as factor
# Note: Dont change the levels order
ds$buggy <- factor(ifelse(ds$num_issues == 0,"buggy0", "buggy1"), levels=c('buggy1', 'buggy0'))

# Set the features as Numeric
ds$lines = as.numeric(ds$lines)
ds$cyclomatic = as.numeric(ds$cyclomatic)
ds$churn_adds = as.numeric(ds$churn_adds)
ds$churn_dels = as.numeric(ds$churn_dels)
ds$num_commits = as.numeric(ds$num_commits)
ds$num_developers = as.numeric(ds$num_developers)
ds$num_pre_release_issues = as.numeric(ds$num_pre_release_issues)

# to dplyr
# ========
ds = tbl_df(ds)

evaluatePredictionModels = function(data.train, data.test){
    project = as.character(data.train$project)[1]
    release.train = data.train$release_id[1]
    release.test = data.test$release_id[1]
    
    f = as.formula("buggy ~ lines + cyclomatic + churn +churn_adds + churn_dels+ 
                   num_commits + num_developers + num_pre_release_issues")
    
    flog.info("%s - r.train: %s  - r.test: %s - RF", project, release.train, release.test)
    set.seed(123)
    model.rf <- train(f, data = data.train, metric = "ROC", preProcess=c("pca"), 
                      method = "rf",
                      trControl = ctrl.oob)
    incremental.prediction(model.rf, data.test)
    Get.traditional.Performance(model.rf, data.test, save.flag=TRUE)
    
    
    flog.info("%s - r.train: %s  - r.test: %s - LOG", project, release.train, release.test)
    set.seed(123)
    model.log <- train(f, data = data.train, metric = "ROC", preProcess=c("pca"),
                       method = "glm", family = binomial,
                       trControl = ctrl.repeatedcv)
    incremental.prediction(model.log, data.test)
    Get.traditional.Performance(model.log, data.test, save.flag=TRUE)
    
    
    flog.info("%s - r.train: %s  - r.test: %s - NB", project, release.train, release.test)
    set.seed(123)
    model.nb <- train(f, data = data.train, metric = "ROC", preProcess=c("pca"),
                      method = "nb",
                      trControl = ctrl.repeatedcv)
    incremental.prediction(model.nb, data.test)
    Get.traditional.Performance(model.nb, data.test, save.flag=TRUE)
    
    
    flog.info("%s - r.train: %s  - r.test: %s - CART", project, release.train, release.test)
    set.seed(123)
    model.cart <- train(f, data = data.train, metric = "ROC", preProcess=c("pca"),
                        method = "rpart", tuneLength = 5,
                        trControl = ctrl.repeatedcv)
    incremental.prediction(model.cart, data.test)
    Get.traditional.Performance(model.cart, data.test, save.flag=TRUE)
    
    
    flog.info("%s - r.train: %s  - r.test: %s - LDA", project, release.train, release.test)
    set.seed(123)
    model.lda <- train(f, data = data.train, metric = "ROC", preProcess=c("pca"),
                       method = "lda",
                       trControl = ctrl.repeatedcv)
    incremental.prediction(model.lda, data.test)
    Get.traditional.Performance(model.lda, data.test, save.flag=TRUE)

    
    flog.info("%s - r.train: %s  - r.test: %s - QDA", project, release.train, release.test)
    set.seed(123)
    model.qda <- train(f, data = data.train, metric = "ROC", preProcess=c("pca"),
                       method = "qda",
                       trControl = ctrl.repeatedcv)
    incremental.prediction(model.qda, data.test)
    Get.traditional.Performance(model.qda, data.test, save.flag=TRUE)

    
    # flog.info("%s - r.train: %s  - r.test: %s - SVM", project, release.train, release.test)
    # set.seed(123)
    # model.svm <- train(f, data = data.train, metric = "ROC", preProcess=c("pca"),
    #                    method = "svmLinear",
    #                    trControl = ctrl.repeatedcv)
    # incremental.prediction(model.svm, data.test)
    # Get.traditional.Performance(model.svm, data.test, save.flag=TRUE)
    # 
    # 
    # flog.info("%s - r.train: %s  - r.test: %s - C50", project, release.train, release.test)
    # set.seed(123)
    # model.c5.0 <- train(f, data = data.train, metric = "ROC", preProcess=c("pca"),
    #                     method = "C5.0",
    #                     trControl = ctrl.repeatedcv)
    # incremental.prediction(model.c5.0, data.test)
    # Get.traditional.Performance(model.c5.0, data.test, save.flag=TRUE)
    # 
    # 
    # flog.info("%s - r.train: %s  - r.test: %s - KNN", project, release.train, release.test)
    # set.seed(123)
    # model.knn <- train(f, data = data.train, metric = "ROC", preProcess=c("pca"),
    #                    method = "knn", tuneGrid = expand.grid(k=c(5, 7, 9, 13,  17)),
    #                    trControl = ctrl.repeatedcv)
    # incremental.prediction(model.knn, data.test)
    # Get.traditional.Performance(model.knn, data.test, save.flag=TRUE)
    
    
    # Evaluate the models in the Testing-data
    flog.info("%s - r.train: %s  - r.test: %s - Get.traditional.Performance", project, release.train, release.test)
    list.models = list(model.rf = model.rf, model.log = model.log, 
                       model.nb = model.nb, model.cart = model.cart,
                       model.lda = model.lda, model.qda = model.qda)
    perf.metrics = lapply(list.models, Get.traditional.Performance, data.test)
    perf.metrics = as.data.frame(do.call(rbind, perf.metrics))
    
    perf.metrics$release.train = release.train
    perf.metrics$release.test = release.test
    return(perf.metrics)
}


train.test.models = function(data){
    project = as.character(data$project)[1]
    flog.info("Train and Test Models in: %s", project)

    # Get the dataset per release
    ds.r0 = data %>% filter(release_id==0)
    ds.r1 = data %>% filter(release_id==1)
    ds.r2 = data %>% filter(release_id==2)
    
    # Train in one release and Test in the next
    
    start.time = Sys.time()
    perf.metrics.r0.r1 = evaluatePredictionModels(data.train = ds.r0, 
                                                  data.test = ds.r1)
    end.time = Sys.time()
    flog.warn("Time First-evaluation: %s", end.time - start.time)
    
    start.time = Sys.time()
    perf.metrics.r1.r2 = evaluatePredictionModels(data.train = ds.r1, 
                                                  data.test = ds.r2)
    end.time = Sys.time()
    flog.warn("Time Second-evaluation: %s", end.time - start.time)
    
    perf.metrics = rbind(perf.metrics.r0.r1, perf.metrics.r1.r2)
    perf.metrics = as.data.frame(perf.metrics)
    return(perf.metrics)
}

# rm(list = ls())
# arrange(desc(project)) %>%

start.time = Sys.time()

ds.perf = ds %>% 
          filter(project == "felix") %>%
          group_by(project) %>%
          do(train.test.models(data=.))

ds.perf

end.time = Sys.time()

flog.warn("Time Entire-evaluation: %s", end.time - start.time)



