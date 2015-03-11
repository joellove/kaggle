setwd("/home/vcrm_6442267/workspace/r/kaggle")

#### HDFS 접속(배치계)
library( "rmr2" )
library("rhdfs")

hdfs.init()
hdfs.ls("/user/hive/warehouse/kaggle.db/driver_telematics_analysis")

#### DTW 예제
sc <- read.table("../test/synthetic_control.data", header=F, sep="")  
n <- 10
s <- sample(1:100, n)
idx <- c(s, 100+s, 200+s, 300+s, 400+s, 500+s)
sample2 <- sc[idx,]
observedLabels <- c(rep(1,n), rep(2,n), rep(3,n), rep(4,n), rep(5,n), rep(6,n))
distMatrix <- dist(sample2, method="DTW")

hc <- hclust(distMatrix, method="average")
plot(hc, labels=observedLabels, main="")
memb <- cutree(hc, k=8)
table(observedLabels, memb)

#### 대화형 임팔라 접속
library( "RODBC" )
conn = odbcConnect( "Impala2" )
sqlQuery( conn, "invalidate metadata" )



# 캐글 데이터 가져오기
result = sqlQuery( conn, "select * from kaggle.driver_fixed_speed3
                   where user_id = 1
                   order by user_id, trip_id, seq_num" )
odbcClose(conn)
# trip counting
#result_count <- result[,.N,by=list(user_id, trip_id)][order(N)]

# DTW 라이브러리 로딩
install.packages("dtw")
library(dtw) 

# 두 시계열데이터 DTW 계산
# align <- dtw(result[result$trip_id==1,"velocity"], result[result$trip_id==2,"velocity"], 
#              step=asymmetricP1, keep=T)
# dtwPlotTwoWay(align)

#install.packages("data.table")
#library("data.table")
#dt = data.table(x=rnorm(9), y=rep(c("a","b","c"), each=3), z=rnorm(9))

# DTW계산을 위해 테이블을 unpivot
library(reshape2)
head(result)
tripData <- dcast(result, user_id + trip_id ~ seq_num, value.var = "velocity")
# data.table column 이름 변경
#for (i in 3:202) names(tripData)[i]= paste("t_",i-2, sep="")

# new_section_type    N
# 1:              AA1 2002
# 2:              AA2 2251
# 3:              DD1 1848
# 4:              DD2 2263
# 5:              SS1 2746
# 6:              SS2 3864

# 길이가 서로 다른 시계열 데이터의 DTW를 계산하는 함수 생성
dtwOmitNA <-function (x,y)
{
  a<-na.omit(x)
  b<-na.omit(y)
  return(dtw(a,b,distance.only=TRUE)$normalizedDistance)
}

## create a new entry in the registry with two aliases
pr_DB$delete_entry("dtwOmitNA")
pr_DB$set_entry(FUN = dtwOmitNA, names = c("dtwOmitNA"))

# 한 사용자의 주행 200개에 대해 DTW를 계산
distMatrix <- dist(tripData[1:200,-(1:2)], method="dtwOmitNA")

# 클러스터링
hc <- hclust(distMatrix, method="average")
observedLabels <- c(1:200)

#시각화
library(ggplot2)
plot(hc, labels=observedLabels, main="")
rect.hclust(hc, k=2, border="red")
groups <- cutree(hc, k=2)

#par(mfrow=c(2,2))
#layout(matrix(c(1,1,2,3), 2, 2, byrow = TRUE), 
#       widths=c(3,1), heights=c(1,2))
#rm(list = ls())  # clear objects  
graphics.off()    # close graphics windows

#plot(result$velocity, type="l")
#qplot(seq_num, velocity, data = result, colour = accel_type)
#ggplot(data=result, aes(x=seq_num, y=velocity)) + 
#  geom_line(aes(colour = accel_type)) + geom_smooth()

a <- ggplot(data=result[result$trip_id==c(34),], aes(seq_num, velocity, fill=accel_type)) + 
  geom_bar(stat="identity") + ggtitle("Trip 34")
b <- ggplot(data=result[result$trip_id==c(49),], aes(seq_num, velocity, fill=accel_type)) + 
  geom_bar(stat="identity") + ggtitle("Trip 49")
c <- ggplot(data=result[result$trip_id==c(11),], aes(seq_num, velocity, fill=accel_type)) + 
  geom_bar(stat="identity") + ggtitle("Trip 11")
d <- ggplot(data=result[result$trip_id==c(19),], aes(seq_num, velocity, fill=accel_type)) + 
  geom_bar(stat="identity") + ggtitle("Trip 19")
e <- ggplot(data=result[result$trip_id==c(15),], aes(seq_num, velocity, fill=accel_type)) + 
  geom_bar(stat="identity") + ggtitle("Trip 15")
f <- ggplot(data=result[result$trip_id==c(43),], aes(seq_num, velocity, fill=accel_type)) + 
  geom_bar(stat="identity") + ggtitle("Trip 43")
g <- ggplot(data=result[result$trip_id==c(6),], aes(seq_num, velocity, fill=accel_type)) + 
  geom_bar(stat="identity") + ggtitle("Trip 6")
h <- ggplot(data=result[result$trip_id==c(38),], aes(seq_num, velocity, fill=accel_type)) + 
  geom_bar(stat="identity") + ggtitle("Trip 38")
multiplot(a, b, c, d, e, f, g, h, cols=2)
#geom_line(aes(colour = accel_type))
#scale_color_manual(values = c("blue", "red", "yellow"))
#scale_color_hue()


required.density <- 1 # the density of shading lines, in lines per inch
rect.hclust.nice(hc, k = 2, border='blue', labels=observedLabels,density=required.density)


########## Custom 함수 리스트 ###################################################################
rect.hclust.nice = function (tree, k = NULL, which = NULL, x = NULL, h = NULL, border = 2,
                             cluster = NULL,  density = NULL,labels = NULL, ...)
{
  if (length(h) > 1 | length(k) > 1)
    stop("'k' and 'h' must be a scalar")
  if (!is.null(h)) {
    if (!is.null(k))
      stop("specify exactly one of 'k' and 'h'")
    k <- min(which(rev(tree$height) < h))
    k <- max(k, 2)
  }
  else if (is.null(k))
    stop("specify exactly one of 'k' and 'h'")
  if (k < 2 | k > length(tree$height))
    stop(gettextf("k must be between 2 and %d", length(tree$height)),
         domain = NA)
  if (is.null(cluster))
    cluster <- cutree(tree, k = k)
  clustab <- table(cluster)[unique(cluster[tree$order])]
  m <- c(0, cumsum(clustab))
  if (!is.null(x)) {
    if (!is.null(which))
      stop("specify exactly one of 'which' and 'x'")
    which <- x
    for (n in 1L:length(x)) which[n] <- max(which(m < x[n]))
  }
  else if (is.null(which))
    which <- 1L:k
  if (any(which > k))
    stop(gettextf("all elements of 'which' must be between 1 and %d",
                  k), domain = NA)
  border <- rep(border, length.out = length(which))
  labels <- rep(labels, length.out = length(which))
  retval <- list()
  for (n in 1L:length(which)) {
    rect(m[which[n]] + 0.66, par("usr")[3L], m[which[n] +
                                                 1] + 0.33, mean(rev(tree$height)[(k - 1):k]), border = border[n], col = border[n], density = density, ...)
    text((m[which[n]] + m[which[n] + 1]+1)/2, grconvertY(grconvertY(par("usr")[3L],"user","ndc")+0.02,"ndc","user"),labels[n])
    retval[[n]] <- which(cluster == as.integer(names(clustab)[which[n]]))
  }
  invisible(retval)
}

# Multiple plot function
#
# ggplot objects can be passed in ..., or to plotlist (as a list of ggplot objects)
# - cols:   Number of columns in layout
# - layout: A matrix specifying the layout. If present, 'cols' is ignored.
#
# If the layout is something like matrix(c(1,2,3,3), nrow=2, byrow=TRUE),
# then plot 1 will go in the upper left, 2 will go in the upper right, and
# 3 will go all the way across the bottom.
#
multiplot <- function(..., plotlist=NULL, file, cols=1, layout=NULL) {
  require(grid)
  
  # Make a list from the ... arguments and plotlist
  plots <- c(list(...), plotlist)
  
  numPlots = length(plots)
  
  # If layout is NULL, then use 'cols' to determine layout
  if (is.null(layout)) {
    # Make the panel
    # ncol: Number of columns of plots
    # nrow: Number of rows needed, calculated from # of cols
    layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
                     ncol = cols, nrow = ceiling(numPlots/cols))
  }
  
  if (numPlots==1) {
    print(plots[[1]])
    
  } else {
    # Set up the page
    grid.newpage()
    pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))
    
    # Make each plot, in the correct location
    for (i in 1:numPlots) {
      # Get the i,j matrix positions of the regions that contain this subplot
      matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))
      
      print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
                                      layout.pos.col = matchidx$col))
    }
  }
}