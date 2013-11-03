library(ggplot2)
library(plyr)
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
df$t.diff[df$breath_n==1] <- NA # remove those differences between last and first observations
head(df)

# Max n breaths
max.breaths <- ddply(df, .(rr_id), summarise, max(breath_n, na.rm = TRUE))
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
t7.rr_id <- df$rr_id[df$breath_n == 7]
t7.data <- df$data[df$breath_n == 7]
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

# get single observation data
df$uniq <- !duplicated(df$rr_id)
sum(df$uniq)
df2 <- df[df$uniq == 1,]
head(df2)

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

c.test.results <- cor.test(x = df2$tfl.rr, y = df2$t7.tdiff, alternative = "two.sided", 
                           method = "pearson")