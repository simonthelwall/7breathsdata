library(rjson)
setwd("/home/simon/R_stuff/breaths/7breathsdata/R_analysis")
json_file <- "sample.txt"
j.data <- fromJSON(paste(readLines(json_file), collapse=""))
#j.data <- fromJSON(json_file, collapse=""))
head(j.data)
j.data[[1]]
j.data[[1]]$data
j.data[[1]]$data[1]

a <-matrix(NA, nrow = 1, ncol = 4)
a <- as.data.frame(a)
names(a) <- c("rr_id", "data", "displayed_rr", "device")

for (i in 1:length(j.data)){
  data <- unlist(j.data[[i]]$data)
  rr_id <- rep(j.data[[i]]$rr_id, length(data))
  displayed_rr <- rep(j.data[[i]]$displayedRR, length(data))
  device <- rep(j.data[[i]]$device, length(data))
  b <- as.data.frame(cbind(rr_id, data, displayed_rr, device))
  a <- rbind(a, b)
}
a[1,]
a <- a[2:length(a$rr_id), ]
head(a)