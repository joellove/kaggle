setwd("/home/vcrm_6442251/Workspace/kaggle/driver_telmatics_analysis")

library("sqldf")
library("RODBC")
library("reshape2")
library("dtw")

executeSql <- function(sql) {   
    conn <- odbcConnect("Impala2")
    result <- sqlQuery(conn, sql)
    odbcClose(conn)
    return (result)
}

# getting derived data from kaggle
kaggle_derived_sql <- "select * from kaggle.trip_summary_v1 order by user_id, trip_id"
kaggle_derived_data <- executeSql(kaggle_derived_sql)

extract_data <- sqldf("select trip_id, t_dist, avg_v, max_v 
                                from kaggle_derived_data 
                                where user_id = 1
                                order by user_id, trip_id")

kmeans_data <- extract_data
# kmeans_data$trip_id <- NULL

plotting <- function(x_axis, y_axis, center_cnt){
    km_result <- kmeans(kmeans_data, iter.max =  200, centers = center_cnt)
    table(extract_data$trip_id, km_result$cluster)
    
    axises <- c(x_axis, y_axis)
    
    plot(kmeans_data[axises], col = km_result$cluster)
    points(km_result$centers[,axises],col=1:3,pch=8,cex=2)
}

plotting("t_dist", "avg_v", 4)

km_result <- kmeans(kmeans_data, iter.max =  200, centers = 4)
x <- table(extract_data$trip_id, km_result$cluster)

plot(kmeans_data[c("t_dist", "avg_v", "max_v")], col = km_result$cluster)
points(km_result$centers[,c("t_dist", "avg_v")],col=1:3,pch=8,cex=2)




