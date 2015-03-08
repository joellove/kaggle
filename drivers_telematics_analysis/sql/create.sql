/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  USED SCHEMA : KAGGLE
  CREATED BY : Joel Lee
  SINCE  : 2015.03.02

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

create database if not exists kaggle
;

drop table kaggle.driver_telematics_source;
create table kaggle.driver_telematics_source
(
	user_id		String,
	trip_id		String,
	seq_num		Bigint,
	x			Double,
	y			Double,
	distance	Double,
	velocity	String,
	accelation	String,
	accel_id	Int,
	accel_type int
)
row format delimited fields terminated by ','
stored as textfile
;

hive -e "load data local inpath '/home/vcrm_6442251/data/kaggle/driver_telematics_analsys/joel/result3/*' into table kaggle.driver_telematics_source"

select count(*) as row_count from kaggle.driver_telematics_source
;

--원본 건수 : 357,434,921
--1,2번째 레코드 제거 : 1,094,400
-- --변환 건수 : 356,340,521

select count(*)
from
(
  select user_id from kaggle.driver_telematics_source
  group by user_id
)a
;
--user id : 2736

drop table if exists kaggle.driver_telematics_source2;
create table kaggle.driver_telematics_source2
as
select
    cast(user_id as int) as user_id
   , cast(trip_id as int) as trip_id
   , seq_num
   , distance
    , round(cast(velocity as double), 1) as velocity
    ,round(cast(accelation  as double), 1) as accelation
   , accel_id
   ,accel_type
from kaggle.driver_telematics_source
;


select
  *
from kaggle.driver_telematics_source2
where user_id = 1 and trip_id = 1
;

-- 정속구간 파생
drop table if exists kaggle.driver_fixed_speed;
create table kaggle.driver_fixed_speed
as
select
    user_id
    , trip_id
    , seq_num
    , distance
    , velocity
    , accelation
    , accel_id
    , accel_type
 ,sum(case when A.accel_id_change = 1 then 1 else 0 end) over (partition by user_id, trip_id order by seq_num) as accel_id_seq
 ,sum(case when A.accel_type_change = 1 then 1 else 0 end) over (partition by user_id, trip_id order by seq_num) as accel_type_seq
 from
(
  select
   user_id
   , trip_id
   , seq_num
   , distance
   , velocity
   , accelation
   , accel_id
   , accel_type
   , case when lag(accel_id, 1) over (partition by user_id, trip_id order by seq_num) = accel_id then 0 else 1 end as accel_id_change
   , case when lag(accel_type, 1) over (partition by user_id, trip_id order by seq_num) = accel_type then 0 else 1 end as accel_type_change
  from kaggle.driver_telematics_source2
) A
;

select count(*) from kaggle.driver_fixed_speed;

select
  *
from kaggle.driver_fixed_speed
where user_id = 2109 and trip_id = 175
;

-- , SUM(CASE WHEN acceleration >= 7.0  THEN 1 ELSE 0 END) AS abrubt_accel_cnt
-- , SUM(CASE WHEN acceleration >= 7.0 THEN 1 ELSE 0 END)/COUNT(1)::REAL * 100 AS abrubt_accel_pct
-- , SUM(CASE WHEN acceleration <=-7.0 THEN 1 ELSE 0 END) AS abrubt_decel_cnt
-- , SUM(CASE WHEN acceleration <=-7.0 THEN 1 ELSE 0 END)/COUNT(1)::REAL * 100  AS abrubt_decel_pct
-- , SUM((CASE WHEN velocity >= 120 THEN 1 ELSE 0 END))*2 AS over_spd_sec
-- , SUM((CASE WHEN velocity > 3 AND velocity <= 30 THEN 1 ELSE 0 END))*2 AS low_spd_sec
-- , SUM((CASE WHEN velocity > 30 AND velocity <= 60 THEN 1 ELSE 0 END))*2 AS mid_low_spd_sec
-- , SUM((CASE WHEN velocity > 60 AND velocity <= 90 THEN 1 ELSE 0 END))*2 AS mid_spd_sec
-- , SUM((CASE WHEN velocity > 90 AND velocity <= 120 THEN 1 ELSE 0 END))*2 AS mid_high_spd_sec
-- , SUM((CASE WHEN velocity > 120 THEN 1 ELSE 0 END))*2 AS high_spd_sec
-- , SUM(CASE WHEN acceleration >= 7.0 AND  acceleration <= 10.0 THEN 1 ELSE 0 END) AS rapid_accel_1
-- , SUM(CASE WHEN acceleration >= 11.0 AND acceleration <= 13.0 THEN 1 ELSE 0 END) AS rapid_accel_2
-- , SUM(CASE WHEN acceleration >= 14.0 AND acceleration <= 17.0 THEN 1 ELSE 0 END) AS rapid_accel_3
-- , SUM(CASE WHEN acceleration >= 18.0 THEN 1 ELSE 0 END) AS rapid_accel_4
-- , SUM(CASE WHEN acceleration <= -21.0 THEN 1 ELSE 0 END) AS rapid_decel_1
-- , SUM(CASE WHEN acceleration <= -18.0 AND acceleration >= -20.0 THEN 1 ELSE 0 END) AS rapid_decel_2
-- , SUM(CASE WHEN acceleration <= -14.0 AND acceleration >= -17.0 THEN 1 ELSE 0 END) AS rapid_decel_3
-- , SUM(CASE WHEN acceleration <= -11.0 AND acceleration >= -13.0 THEN 1 ELSE 0 END) AS rapid_decel_4
-- , SUM(CASE WHEN acceleration <= -7.0 AND acceleration >= -10.0 THEN 1 ELSE 0 END) AS rapid_decel_5
-- , COUNT(1) AS velocity_lvl_cnt

/* SPEED_CAT
  1 - > 130 KPH > 80 MPH
  2 - 101-130 KPH 65-80 MPH
  3 - 91-100 KPH 55-64 MPH
  4 -71-90 KPH 41-54 MPH
  5 - 51-70 KPH 31-40 MPH
  6 - 31-50 KPH 21-30 MPH
  7 - 11-30 KPH 6-20 MPH
  8 - < 11 KPH < 6 MPH
*/

-- 속도 구간 파생
drop table if exists kaggle.driver_fixed_speed2;
create table kaggle.driver_fixed_speed2
AS
SELECT
    *
    , case
        when velocity <= 10 then 8
        when  velocity > 10 and velocity <= 30 then 7
        when  velocity > 30 and velocity <= 50 then 6
        when  velocity > 50 and velocity <= 70 then 5
        when  velocity > 70 and velocity <= 90 then 4
        when  velocity > 90 and velocity <= 100 then 3
        when  velocity > 100 and velocity <= 130 then 2
        when  velocity > 130  then 1
    end as velocity_type
from kaggle.driver_fixed_speed
;

-- 속도 구간 파생2
drop table if exists kaggle.driver_fixed_speed3;
create table kaggle.driver_fixed_speed3
AS
select
    a.*
    ,b.section_type
from
 (select *, case when accelation = velocity then 0 else accelation end as accelation1 from kaggle.driver_fixed_speed2) a,
 (select *, case when accel_type = 1
             then case when min_v1 < 5
                       then case when max_v1 < 30 then "A01" else "A02" end
                       else
                            case when min_v1 < 30 then "A03" else case when min_v1 < 60 then "A04" else "A05" end
                            end
                  end
             else
                  case when accel_type = 2
                       then
                            case when max_v1 < 5
                                 then case when min_v1 < 30 then "D01" else "D02" end
                                 else
                                      case when max_v1 < 30 then "D03" else case when max_v1 < 60 then "D04" else "D05" end
                                      end
                            end
                       else
                            case when max_v1  < 30
                                 then case when max_v1 < 15 then "S01" else "S02" end
                                 else
                                      case when max_v1 < 60 then "S03" else case when max_v1 < 90 then "S04" else "S05" end
                                      end
                            end
                  end
        end as section_type
 from
   ( select user_id, trip_id, accel_type_seq, avg(accel_type) as accel_type , sum(distance) as dist, count(seq_num) as cnt_s ,
        avg(velocity) as avg_v, max(velocity) as max_v, min(velocity) as min_v, round(max(velocity) / 5) * 5 as max_v1 , round(min(velocity) / 5) * 5 as min_v1,
        avg(accelation1) as avg_a, max(accelation1) as max_a, min(accelation1) as min_a, stddev(accelation1) as stddev_a
    from
        (select *, case when accelation = velocity then 0 else accelation end as accelation1
        from kaggle.driver_fixed_speed2 ) c
    group by user_id, trip_id, accel_type_seq ) a
) b
where
    a.user_id = b.user_id and a.trip_id = b.trip_id and a.accel_type_seq = b.accel_type_seq

-- 구간별 row_number  파생
drop table if exists kaggle.driver_fixed_speed4;
create table kaggle.driver_fixed_speed4
AS
select
    *
    , row_number() over(partition by user_id, trip_id, accel_type order by seq_num) as accel_type_num
from kaggle.driver_fixed_speed3
where user_id = 1 and trip_id = 1


row_number() over(order by x, property) as row_number


-- 가속/감속/정속 구간별 요약 테이블 생성
drop table if exists kaggle.driver_accel_summary;
create table kaggle.driver_accel_summary
as
select
   cast(user_id as int) as user_id
  , cast(trip_id as int) as trip_id
  , accel_id                                                        -- 가속구분 : 1-정속, 2-감속, 3-정속
  , AVG(velocity) as velocity_avg
  , MAX(velocity) as velocity_max
  , MIN(velocity) as velocity_min
  , AVG(accelation) as accel_avg
  , MAX(accelation) as accel_max
  , MIN(accelation) as accel_min
  , AVG(distance) as distance_avg
  , MAX(distance) as distance_max
  , MIN(distance) as distance_min
  , count(*) as driving_sec
from kaggle.driver_telematics_analysis
group by user_id, trip_id, accel_id
;
-- 1,641,600

-- outlier 제거
drop table if exists  kaggle.driver_accel_summary_filter;
create table kaggle.driver_accel_summary_filter
AS
SELECT
 *
from kaggle.driver_accel_summary
where
  velocity_avg < 300
  and velocity_max < 300
;
-- 1,627,211


