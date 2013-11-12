library(ggplot2)
library(plyr)
library(xtable)

printPVal <- function(x){
  ifelse(x < 0.001, "< 0.001", 
         ifelse(x < 0.05, "< 0.05", round(x,2)))
}

setwd("/home/simon/R_stuff/breaths/7breathsdata/R_analysis")
load("converted.RData")
head(df)

df$data <- as.numeric(df$data)

# data stored as number of seconds since 1970, to millisecond precision. 
table(nchar(df$data))
df$t <- as.POSIXct(df$data, tz = "GMT", origin = 0)
head(df$t)
origin <- as.POSIXct("1970-01-01", tz = "GMT")
origin + (1374097160823)/1000

# Generate differences between breaths ####
# breath sequence number
df$breath.n <- sequence(rle(df$rr_id)$lengths)
table(df$breath.n)

# Calculate time differences
df$t.diff[2:length(df$rr_id)] <- diff(df$data,1)/1000
df$t.diff[df$breath.n==1] <- NA # remove those differences between last and first observations
head(df)

# Max n breaths
max.breaths <- ddply(df, .(rr_id), summarise, max(breath.n, na.rm = TRUE))
head(max.breaths)
names(max.breaths) <- c("rr_id", "max")
table(max.breaths$max.breaths)
df <- join(df, max.breaths)
rm(max.breaths)
head(df)

# time of first and last breaths
tfl <- ddply(df, .(rr_id), summarise, tf = min(data), tl = max(data))
head(tfl)
df <- join(df, tfl)
rm(tfl)
head(df)

# time of seventh breath
t7.rr_id <- df$rr_id[df$breath.n == 7]
t7.data <- df$data[df$breath.n == 7]
length(t7.rr_id)
length(t7.data)
t7 <- as.data.frame(cbind(t7.rr_id, t7.data), stringsAsFactors = FALSE)
names(t7) <- c("rr_id", "t7")
t7$t7 <- as.numeric(t7$t7)
head(t7)
df <- join(df, t7)
rm(t7)
head(df)

# Calculate some respiration rates
df$t7.tdiff <- (df$t7 - df$tf)/1000 # time in seconds between first and seventh breath
df$tfl.diff <- ((df$tl - df$tf)/1000)/60 # time in minutes 
df$tfl.rr <- df$max/df$tfl.diff # breaths per minute
head(df)

# Important to consider bias by recording > 1 minute.
# Therefore need to consider stopping all observations at 1 minute after first breath. 
# Breaths will not fall on 1 minute time exactly. Want number of breaths completed in one minute. 
# Therefore drop any observations > 1 minute. 
df$tff <- ((df$data/1000) - (df$tf/1000))/60 # time difference from first breath in minutes

df$rr.1.min <- df$breath.n/df$tff
df$rr.1.min[df$tff>1] <- NA # remove measures > 1 min.
df$rr.1.min[is.infinite(df$rr.1.min)] <- NA #remove divide by zero errors.
head(df)
head(df$rr_id[df$breath.n==df$max])
df$breath.n.2 <- df$breath.n # copy breath number to obtain breath number closest to 1 minute
df$breath.n.2[df$tff>1] <- NA  # get rid of copies > 1 minute
max.2 <- ddply(df, .(rr_id), summarise, max.breath.2 = max(breath.n.2))
df <- join(df, max.2) # get a column of the max number of breaths within one minute. This is the 1 minute respiration rate
rm(max.2)

df[df$rr_id == "64979374a3614043809b9c14156b42d3",]
qplot(tff, data = df, geom = "histogram")
qplot(t.diff, data = df, geom = "histogram", binwidth = 1)
range(df$t.diff, na.rm = TRUE)
levels(factor(df$rr_id[df$t.diff>30])) #11 records with t.diff> 30
df[df$rr_id == "09b8ba29d7ad4f09a4cf9b2075fd16b0",]
df$data[1]/1000
# df$data[5]/1000
# (df$data[5]/1000) - (df$data[1]/1000)

# get single observation data
df$uniq <- ifelse(!duplicated(df$rr_id),1,0)
sum(df$uniq)
df2 <- df[df$uniq == 1,]
head(df2)
table(df2$uniq, useNA = "ifany")

png("correlation.png", height = 500, width = 500, res = 300)
p <- ggplot(df2, aes(x = tfl.rr, y = t7.tdiff)) + geom_point()
p + scale_x_continuous("Breaths per minute") + scale_y_continuous("Time to seven breaths (s)")
dev.off()

png("log_correlation.png", height = 500, width = 500, res = 300)
p <- ggplot(df2, aes(x = log(tfl.rr), y = log(t7.tdiff))) + geom_point()
p + scale_x_continuous("Log breaths per minute") + 
  scale_y_continuous("log time to seven breaths (s)")
dev.off()

q <- ggplot(df2, aes(x = t7.tdiff)) + geom_histogram(binwidth = 1)
q + scale_x_continuous("Time to seven breaths (s)")

q <- ggplot(df2, aes(x = tfl.rr)) + geom_histogram()
q + scale_x_continuous("Respiration rate (breaths per minute)")

correlation <- cor(x = df2$tfl.rr, y = df2$t7.tdiff, use = "complete.obs")
correlation <- cor(x = df2$max.breath.2, y = df2$t7.tdiff, use = "complete.obs")

c.test.results <- cor.test(x = df2$tfl.rr, y = df2$t7.tdiff, alternative = "two.sided", 
                           method = "pearson")

printPVal(c.test.results$p.value)
       

# Prediction ####
# Given the correlation between t7.tdiff and 1 min rr, how good is the prediction of rr, for a given t7/
range(df$t7.tdiff, na.rm = TRUE)
t7.tdiff <- seq(10, 30, 2)
rr.p <- rep(NA, 11)
p.frame <- as.data.frame(cbind(t7.tdiff, rr.p), stringsAsFactors = FALSE)
rm(t7, rr.p)

t7.m <- lm(log(tfl.rr) ~ log(t7.tdiff), data = df)
summary(t7.m)
predicted <- round(exp(predict(t7.m, newdata = p.frame, interval = "prediction")),2)
p.frame$rr.p <- NULL
p.frame <- cbind(p.frame, predicted)
p.frame$fit2 <- paste(sprintf("%.2f", p.frame$fit), " (", sprintf("%.2f", p.frame$lwr), "-", 
                      sprintf("%.2f", p.frame$upr), ")", sep = "")
p.frame$fit <- NULL
p.frame$lwr <- NULL
p.frame$upr <- NULL
names(p.frame) <- c("Time to seven breaths (s)", "\\shortstack{Predicted respiration rate \\\\(minutes, with prediction interval)}")
p.frame <- xtable(p.frame, 
                  caption = "Predicted respiration values for given times to seven breaths.",
                  label = "pred.table")
print(p.frame, booktabs = TRUE, include.rownames = FALSE, sanitize.text.function = identity)

# Range subanalysis ####
# tachypnoea > 20 rr in adults. Children, up to 60 is normal.
# tachypnoea <12 rr in adults. 
df2$rr_group <- "under 5"
df2$rr_group[df2$tfl.rr < 5 & !is.na(df2$tfl.rr)] <- "\textless 5"
df2$rr_group[df2$tfl.rr >= 5 & df2$tfl.rr <12 & !is.na(df2$tfl.rr)] <- "5 - 11"
df2$rr_group[df2$tfl.rr > 12 & df2$tfl.rr <21 & !is.na(df2$tfl.rr)] <- "12 - 20"
df2$rr_group[df2$tfl.rr > 20 & df2$tfl.rr <41 & !is.na(df2$tfl.rr)] <- "21 - 40"
df2$rr_group[df2$tfl.rr > 40 & df2$tfl.rr <61 & !is.na(df2$tfl.rr)] <- "41 - 60"
df2$rr_group[df2$tfl.rr > 60  & !is.na(df2$tfl.rr)] <- "\textgreater 60"
table(df2$rr_group, useNA = "ifany")
#df2$n <- 1

df2.2 <- df2[!is.na(df2$t7.tdiff),]
df2.2 <- df2.2[!is.na(df2.2$tfl.rr),]

group.corr <- ddply(df2.2, .(rr_group), summarise, n = sum(uniq), 
                    correlation = cor(x = log(t7.tdiff), y = log(tfl.rr), 
                                      use = "complete.obs"))
group.corr$correlation <- round(group.corr$correlation, 2)
group.corr$rr_group <- factor(group.corr$rr_group, levels = c("\textless 5", "5 - 11", "12 - 20",
                                                              "21 - 40", "41 - 60", "\textgreater 60"))
group.corr <- group.corr[order(group.corr$rr_group),]
group.corr

correlation = cor(x = df2$tfl.rr, y = df2$t7.tdiff, use = "complete.obs")

p <- ggplot(df2, aes(x = log(as.numeric(tfl.rr)), y = log(t7.tdiff))) + geom_point() + facet_wrap(~rr_group, ncol = 1)
p + scale_x_continuous("Log breaths per minute") + 
  scale_y_continuous("log time to seven breaths (s)")