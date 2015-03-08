#!/usr/bin/env bash
# -*- coding:utf-8 -*-
__author__ = 'Joel Lee'

import os
import sys
import math

FILE_SIZE = 1024 * 1024 * 128


def parse(src_dir, target_dir):
    # read driver directory list
    dlist = os.listdir(src_dir)

    # create target directory
    new_f_path = os.path.dirname(target_dir + "/")
    if not os.path.exists(new_f_path):
        os.makedirs(new_f_path)

    # Initial variable
    file_count = 0
    data = ""
    output_file = ""
    record_set = []

    for d in dlist:
        driver_dir = os.path.join(src_dir, d)
        if os.path.isdir(driver_dir):

            driver_name = os.path.basename(driver_dir)

            # read trip file list for driver
            flist = os.listdir(driver_dir)
            for f in flist:

                trip_name = os.path.basename(os.path.splitext(f)[0])

                try:

                    trip_file = open(os.path.join(driver_dir, f), 'r')
                    lines = trip_file.readlines()
                    trip_file.close()

                    # output
                    pre_loc = [0, 0]
                    pre_velocity = 0
                    pre_accel_id = 0
                    seq = 0

                    velocity_start = -1
                    is_accel_same = False

                    for line in lines[2:]:

                        record = Record()

                        if data == "" and len(record_set) == 0:
                            file_count += 1
                            output_file = open(new_f_path + "/" + str(file_count) + ".csv", 'w')

                        loc = line.split(',')

                        # 이동거리 계산
                        x_delta = float(loc[0]) - pre_loc[0]
                        y_delta = float(loc[1]) - pre_loc[1]
                        distance = math.sqrt(pow(x_delta, 2) + pow(y_delta, 2))

                        # 속도 계산
                        # m/sec -> km/hour 변환
                        velocity = distance * 3600 / 1000

                        # 가속도 계산
                        # ( 현재속도 - 이전속도 ) / 걸린 시간
                        if seq == 0:
                            acceleration = 0  # 주행 시작점은 0 세팅
                        else:
                            acceleration = round(velocity - pre_velocity, 1)  #가속도 계산시 정수로 반올림

                        # Trip Sequence
                        seq += 1
                        accel_id = -1

                        # if round(velocity, 1) == 72.8:
                        #     print "p"

                        #가속 : 1, 감속 : 2, 정속 : 3
                        if acceleration >= 0.5:
                            accel_id = 1
                        elif acceleration <= -0.5:
                            accel_id = 2
                        #elif acceleration == 0:
                        else:
                            accel_id = 3

                        # 레코드 객체 저장 : 운전자 ID, 주행 ID, 시퀀스, X, Y, 이동거리, 속도, 가속도, 가속도 구분, 정속구간 구분
                        record.driver_name = driver_name
                        record.trip_name = trip_name
                        record.seq = seq
                        record.location = line.strip()
                        record.distance = distance
                        record.velocity = velocity
                        record.acceleration = acceleration
                        record.accel_id = accel_id
                        record.accel_type = accel_id

                        # 트립 시작 또는 기준점이 변경되는 경우
                        if velocity_start == -1:
                            # 기준점 시작
                            velocity_start = velocity

                        # +-5KPH 를 넘었을 때
                        elif round(absolute_value(velocity_start - velocity), 1) > 5:
                            # 기준점 변경
                            velocity_start = velocity
                            # 정속구간 세팅
                            if len(record_set) > 0:
                                is_accel_change = False
                                for record_tmp in record_set[1:]:
                                    if record_tmp.accel_id != accel_id and record_tmp.accel_id != 3:  # 가속과 감속이 혼재하면 정속 구간임.
                                        is_accel_change = True

                                # +-5KPH 이내 가감속 변화가 있으면, 정속 구간임
                                if is_accel_change == True and is_accel_same != True:
                                    data += record_set[0].output()  # 시작 지점은 원래의 가감속 ID를 보존.
                                    for record_tmp in record_set[1:]:
                                        record_tmp.accel_type = 3
                                        data += record_tmp.output()
                                    is_accel_change = False
                                    record_set = []
                                # 동일 가속 성향인 경우
                                else:
                                    is_accel_same = True

                        # 동일 가속 성향 출력
                        if is_accel_same == True:

                            data += record_set[0].output()  # 시작 지점은 원래의 가감속 ID를 보존.
                            for record_tmp in record_set[1:]:
                                record_tmp.accel_type = accel_id
                                data += record_tmp.output()
                            record_set = []
                            is_accel_same = False
                            velocity_start = velocity

                        record_set.append(record)

                        # 파일 생성
                        if len(data) >= FILE_SIZE:
                            for record_tmp in record_set:
                                data += record_tmp.output()
                            record_set = []
                            output_file.write(data)
                            output_file.close()
                            data = ""

                        pre_loc = [float(loc[0]), float(loc[1])]
                        pre_velocity = velocity
                        pre_accel_id = accel_id

                except OSError as e:
                    print e

    # 잔반 처리
    if data != "":
        for record_tmp in record_set:
            data += record_tmp.output()
        record_set = []
        output_file.write(data)
        output_file.close()


class Record:
    driver_name = ""
    trip_name = ""
    seq = 0
    location = ""
    distance = 0
    velocity = 0
    acceleration = 0
    accel_id = 0
    accel_type = 0

    def output(self):
        return self.driver_name + "," + self.trip_name + "," + str(self.seq) + "," + self.location + "," + str(
            self.distance) + "," + str(self.velocity) + "," + str(self.acceleration) + "," + str(
            self.accel_id) + "," + str(self.accel_type) + "\n"


def absolute_value(x):
    if x < 0:
        return -x
    else:
        return x


if __name__ == "__main__":
    # src_dir = r"D:\10.study\Kaggle\drivers_telematics_analysis\test"
    #target_dir = r"D:\10.study\Kaggle\drivers_telematics_analysis\output_test"
    #parse(src_dir, target_dir)
    dir_path = sys.argv
    parse(dir_path[1], dir_path[2])