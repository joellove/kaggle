#!/usr/bin/env bash
# -*- coding:utf-8 -*-
__author__ = 'Joel Lee'

import os
import math

def parse(src_dir, target_dir):

    # read driver directory list
    dlist = os.listdir(src_dir)

    for d in dlist:
        driver_dir = os.path.join(src_dir, d)
        if os.path.isdir(driver_dir):

            driver_name = os.path.basename(driver_dir)

            # read trip file list for driver
            flist = os.listdir(driver_dir)
            for f in flist:

                trip_name = os.path.basename(os.path.splitext(f)[0])

                trip_file = open(os.path.join(driver_dir,f),'r')
                lines = trip_file.readlines()

                new_f_path = os.path.dirname(target_dir + "/" + driver_name + "/")
                if not os.path.exists(new_f_path):
                    os.makedirs(new_f_path)

                output_file = open(new_f_path + "/" + trip_name + ".new", 'w')
                trip_file.close()

                # output
                pre_loc = [0, 0]
                pre_velocity = 0
                seq = 0;
                for line in lines[2:]:

                    loc = line.split(',')

                    # 이동거리 계산
                    x_delta =float( loc[0]) - pre_loc[0]
                    y_delta = float(loc[1]) - pre_loc[1]
                    distance = math.sqrt(pow(x_delta, 2) + pow(y_delta, 2))

                    # 속도 계산
                    #  m/sec -> km/hour 변환
                    velocity = distance * 3600 / 1000

                    # 가속도 계산
                    # ( 현재속도 - 이전속도 ) / 걸린 시간
                    acceleration = velocity - pre_velocity

                    # 방향 계산
                    # if (x_delta > 0 and y_delta > 0):
                    #     news = 1
                    # elif (x_delta < 0 and y_delta < 0):
                    #     news = 2
                    # elif (x_delta < 0 and y_delta < 0):
                    #     news = 3
                    # elif (x_delta > 0 and y_delta < 0):
                    #     news = 4

                    # Trip Sequence
                    seq = seq + 1
                    accel_property = -1

                    #가속 : 1, 감속:2, 정속: 3
                    if(acceleration > 0):
                        accel_property = 1
                    elif(acceleration < 0):
                        accel_property = 2
                    elif(acceleration == 0):
                        accel_property = 3

                    # 운전자ID, 주행ID, 시퀀스, X, Y, 이동거리, 속도, 가속도, 가속도 구분
                    record = driver_name + "," +  trip_name + "," + str(seq) + "," +  line.strip() + "," +str(distance) + ","  + str(velocity) + "," + str(acceleration) + "," + str(accel_property) + "\n"
                    output_file.write(record)

                    pre_loc = [float( loc[0]), float( loc[1])]
                    pre_velocity = velocity

                output_file.close()


if __name__=="__main__":

    src_dir = r"D:\10.study\Kaggle\drivers_telematics_analysis\drivers"
    target_dir = r"D:\10.study\Kaggle\drivers_telematics_analysis\output"
    # dir_path = sys.argv
    parse(src_dir, target_dir)



