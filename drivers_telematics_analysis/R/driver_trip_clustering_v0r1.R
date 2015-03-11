setwd("/home/vcrm_6442267/workspace/r/kaggle")

# 캐글 데이터 가져오기
result = data.table(sqlQuery( conn, "select * from kaggle.driver_fixed_speed5
                   where user_id = 1
                   order by user_id, trip_id, seq_num" ))

# trip counting
result_count <- result[,.N,by=list(user_id, trip_id)][order(N)]

# 두 가감속 구간 시계열데이터 DTW 계산
align <- dtw(result[result$trip_id==1 & result$section_type_seq==1,"velocity"], 
             result[result$trip_id==1 & result$section_type_seq==22,"velocity"], step=asymmetricP1, keep=T)
dtwPlotTwoWay(align)


# DTW계산을 위해 테이블을 unpivot
library(reshape2)
head(result2)
tripData <- dcast(result, user_id + trip_id + new_section_type + section_type_seq ~ section_type_num, value.var = "velocity")
#for (i in 3:202) names(tripData)[i]= paste("t_",i-2, sep="")


#레이블 지정
labs <- do.call("paste", c(tripData[c(1:4)], sep="_"))
rownames(tripData) <- labs

#tripData <- data.table(tripData)
#tripData[,.N,by=new_section_type]
# new_section_type    N
# 1:              AA1 2002
# 2:              AA2 2251
# 3:              DD1 1848
# 4:              DD2 2263
# 5:              SS1 2746
# 6:              SS2 3864

# 한 사용자의 속도 구간별 DTW를 계산
#distMatrix <- dist(tripData[,-(1:3)], method="dtwOmitNA")
testdf <- tripData[tripData$new_section_type=="SS2" & !is.na(tripData$"10"), -c(1:4)]
distMatrix <- dist(testdf, method="dtwOmitNA")

# distance matrix를 결과 테이블로 변환
#resultdf <- data.frame(t(combn(rownames(testdf),2)), as.numeric(distMatrix))
#names(resultdf) <- c("section_1", "section_2", "distance")
# distance 정렬
#resultdf <- resultdf[order(-resultdf$distance),]

# 클러스터링
hc <- hclust(distMatrix, method="average")
plot(hc, main="")
rect.hclust(hc, k=2, border="red")
groups <- cutree(hc, k=c(2))
AA1 <- data.table(section_type=names(groups), cluster_type=groups)[order(-cluster_type)]
#AA2 <- data.table(section_type=names(groups), cluster_type=groups)[order(-cluster_type)]
#DD1 <- data.table(section_type=names(groups), cluster_type=groups)[order(-cluster_type)]
#DD2 <- data.table(section_type=names(groups), cluster_type=groups)[order(-cluster_type)]
#SS1 <- data.table(section_type=names(groups), cluster_type=groups)[order(-cluster_type)]
#SS2 <- data.table(section_type=names(groups), cluster_type=groups)[order(-cluster_type)]

final <- rbind(AA1, AA2, DD1, DD2, SS1, SS2)
final <- final[order(-cluster_type)]
final[,.N,by=cluster_type]

graphics.off()    # close graphics windows
#rm(list = ls())

a <- ggplot(data=result[result$trip_id==119 & result$section_type=="S03" & result$section_type_seq==111,], aes(section_type_num, velocity, fill=accel_type)) + 
  geom_bar(stat="identity") + ggtitle("1_119_S03_111")
b <- ggplot(data=result[trip_id==176 & section_type=="S03" & section_type_seq==48,], aes(section_type_num, velocity, fill=accel_type)) + 
  geom_bar(stat="identity") + ggtitle("1_176_S03_48")
c <- ggplot(data=result[trip_id==66 & section_type=="S03" & section_type_seq==69,], aes(section_type_num, velocity, fill=accel_type)) + 
  geom_bar(stat="identity") + ggtitle("1_66_S03_69")
d <- ggplot(data=result[trip_id==120 & section_type=="S03" & section_type_seq==16,], aes(section_type_num, velocity, fill=accel_type)) + 
  geom_bar(stat="identity") + ggtitle("1_120_S03_16")
multiplot(a, b, c, d, cols=2)

#geom_line(aes(colour = accel_type))
#scale_color_manual(values = c("blue", "red", "yellow"))
#scale_color_hue()

