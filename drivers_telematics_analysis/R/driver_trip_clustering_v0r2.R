setwd("/home/vcrm_6442267/workspace/r/kaggle")

install.packages("sqldf")
library(sqldf)

# 캐글 데이터 가져오기
drivers <- data.table(sqlQuery( conn, "select user_id
                                        from kaggle.driver_fixed_speed5
                                        group by user_id" ))

submission = NULL
count = 0

for (i in 1:nrow(drivers)) 
{
  driver <- drivers[i,]
  print(count <- count + 1)
  
  for(i in 1:200){
    df = data.table(sqlQuery( conn, paste("select user_id, trip_id, seq_num, velocity
                                         from kaggle.driver_fixed_speed5
                                         where user_id=", i,
                                         "order by user_id, trip_id, seq_num",sep=" ")))
                        
    # DTW계산을 위해 테이블을 unpivot
    trip_df <- dcast(df, user_id + trip_id ~ seq_num, value.var = "velocity")
    #레이블 지정
    #labels <- do.call("paste", c(tripData[c(1:2)], sep="_"))
    labels = sapply(1:200, function(x) paste0(driver,'_', x))
    rownames(trip_df) <- labels
    
    # 한 사용자의 trip별 DTW를 계산
    distMatrix <- dist(trip_df[, -c(1:2)], method="dtwOmitNA")
    
    # 클러스터링
    hc <- hclust(distMatrix, method="average")
    groups <- cutree(hc, k=c(2))
    result <- data.table(driver_trip=names(groups), prob=groups)
    
    # 작은 군집을 가짜 Trip으로 판단
    if(result[,.N,by=prob][1,N] >= result[,.N,by=prob][2,N]){
      result[result$prob==2,2] <- 0
      result[result$prob==1,2] <- 1
    }else{
      result[result$prob==2,2] <- 1
      result[result$prob==1,2] <- 0
    }
    submission <- rbind(submission, result)
  }
}

colnames(submission) = c("driver_trip","prob")
write.csv(submission, "submission.csv", row.names=F, quote=F)
