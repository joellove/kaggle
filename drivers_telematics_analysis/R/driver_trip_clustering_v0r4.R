setwd("/home/vcrm_6442267/workspace/r/kaggle")

#### 대화형 임팔라 접속
library( "RODBC" )
library("sqldf")
conn = odbcConnect( "Impala2" )
sqlQuery( conn, "invalidate metadata" )

# 캐글 데이터 가져오기
#rm(list = ls())  # clear objects 
df = data.frame(sqlQuery( conn, "select *
                                       from kaggle.trip_summary_v1
                                       order by user_id, trip_id"))

drivers <- sqldf("select user_id
                  from df
                  group by user_id
                  order by user_id" )

randomDrivers = drivers[sample(5),]

## feature 선택 max_dd2, std_dd2 제외
feature_set <- c(1,2,89:91,94:96,99:101,104,109:111,114:116) 

# train set 가공
for(i in randomDrivers){
  print(i)
  df_all <- df[df$user_id==i, feature_set]
  # NA를 제거한 training 데이터 셋
  df_train = NULL
  df_train <- na.omit(df_all)
  train_labels <- do.call("paste", c(df_train[c(1:2)], sep="_"))
  # Clustering
  km_result <- kmeans(df_train[,-(1:2)], iter.max = 1000, centers = 2)
  
  #Kmeans 결과 데이터셋
  km_result_df = data.table(driver_trip = train_labels, prob = km_result$cluster)
  
  # 작은 군집을 가짜 Trip으로 판단
  if(km_result_df[,.N,by=prob][prob==1,N] >= km_result_df[,.N,by=prob][prob==2,N]){
    km_result_df$prob[km_result_df$prob==2] <- 0
  }else{
    km_result_df$prob[km_result_df$prob==1] <- 0
    km_result_df$prob[km_result_df$prob==2] <- 1
  }
  
  # clustering 결과를 데이터셋에 컬럼 추가
  df_train <- cbind(df_train, prob = km_result_df$prob)
}


submission = NULL
count = 0

for (i in drivers$user_id) 
{
  #driver <- drivers[i,]
  print(paste0(count <- count + 1,":",i))

  # feature를 selection한 데이터셋
  df_driver <- df[df$user_id==i, feature_set]
  labels_driver <- do.call("paste", c(df_driver[c(1:2)], sep="_"))
  
  # NA를 제거한 training 데이터 셋
  df_driver_current = NULL
  df_driver_current <- na.omit(df_driver)
  train_labels_current <- do.call("paste", c(df_driver_current[c(1:2)], sep="_"))
  row.has.na <- apply(df_driver, 1, function(x){any(is.na(x))})

  # NA 데이터셋
  df_na <- df_driver[row.has.na,]
  na_labels <- do.call("paste", c(df_na[c(1:2)], sep="_"))
  
  # Clustering
  km_result <- kmeans(df_driver_current[,-(1:2)], iter.max = 1000, centers = 2)
  
  #Kmeans 결과 데이터셋
  km_result_df = data.table(driver_trip = train_labels_current, prob = km_result$cluster)
  
  # 작은 군집을 가짜 Trip으로 판단
  if(km_result_df[,.N,by=prob][prob==1,N] >= km_result_df[,.N,by=prob][prob==2,N]){
    km_result_df$prob[km_result_df$prob==2] <- 0
  }else{
    km_result_df$prob[km_result_df$prob==1] <- 0
    km_result_df$prob[km_result_df$prob==2] <- 1
  }
  
  # clustering 결과를 데이터셋에 컬럼 추가
  df_driver_current <- cbind(df_driver_current, prob = km_result_df$prob)
  
  # GLM
  #g = glm(prob ~ avg_accel  +  std_accel +   max_accel  +  avg_dccel  +  std_dccel, data = df_train_sample, family = binomial("logit"))
  #g = glm(prob ~ avg_accel  +  std_accel +   max_accel, data = df_train_sample, family = binomial("logit"))
  tot_train <- rbind(df_driver_current, df_train)
  g = glm(prob ~ avg_aa1+std_aa1+max_aa1+avg_aa2+std_aa2+max_aa2+avg_dd1+std_dd1+max_dd1+
            avg_dd2+avg_ss1+std_ss1+max_ss1+avg_ss2+std_ss2+max_ss2
          , data = tot_train, family = binomial("logit"))
  p = predict(g, df_driver_current, type="response")
  #p[is.na(p)]<-0
  
  #시각화
  #plot(df_train$prob, p, xlab="Observed Values", ylab="Predicted Values")
  
  result = cbind(train_labels_current, p)
  
  if (length(na_labels) > 0) {
    na_result = cbind(na_labels, 0)
    result = rbind(result, na_result)
  }
  
  submission <- rbind(submission, result)
}

# 결과 출력
colnames(submission) = c("driver_trip","prob")
write.csv(submission, "submission.csv", row.names=F, quote=F)
