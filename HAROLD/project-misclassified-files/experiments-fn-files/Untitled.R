library(ggplot2)
library(dtplyr)

setwd("~/Desktop/phd-projects/project-misclassified-files/experiments-fn-files/")

filename = 'results/traditional.performance.csv'

ds = read.csv(filename)

ds = tbl_dt(ds)


df.outs = rbind(
ds %>% select(project, model, release.test, outcome=FN) %>% mutate(outcome.type='FN'),
ds %>% select(project, model, release.test, outcome=TP) %>% mutate(outcome.type='TP'),
ds %>% select(project, model, release.test, outcome=TN) %>% mutate(outcome.type='TN'),
ds %>% select(project, model, release.test, outcome=FP) %>% mutate(outcome.type='FP')
)

df.outs = tbl_dt(df.outs)

# The palette with grey:
cbPalette <- c("#999999",  "#56B4E9", , "#F0E442",  , )

# The palette with black:
cbbPalette <- c("#000000", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")


cbPalette <- c( "#009E73",  "#D55E00", "#0072B2" , "#CC79A7", "#E69F00", "#F0D4C2")

plot.out = ggplot(data=df.outs %>% filter(outcome.type=='FN'), aes(x=model, y=outcome, fill=model)) +
    geom_boxplot(alpha=.7) + 
    geom_point(position = position_jitter(width = 0.3,height = .1), alpha=.6, size=2) +
    scale_x_discrete(limits=c('nb', 'rpart', 'rf', 'glm', 'lda', 'qda'), labels=c('Naive\nBayes', 'CART', 'Rand\nForests', 'Logistic', 'LDA', 'QDA' )) +
    ylab('Num. FN-Files') + xlab('') +
    scale_fill_manual(values=cbPalette, guide = FALSE) +
    theme(axis.text.x = element_text(vjust = 1, face='bold', size=12, color="black")) +
    theme(axis.text.y = element_text(vjust = 1, face='bold', size=10, color="black")) +
    theme(axis.title.y = element_text(vjust = 1, face='bold', size=12, color="black")) 
    
#    scale_fill_brewer(palette="RdYlGn")
    
print(plot.out)

qplot(reorder(model, outcome), outcome, data = df.outs %>% filter(outcome.type=='FN'),     geom  = c("jitter", "boxplot"),   fill = factor(model), alpha = .18)

