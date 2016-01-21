#!/usr/bin/env bash
# -*- coding:utf-8 -*-
__author__ = 'Joel Lee'

import os
import sys
import math

def parse(src_file):
    src_f = open(src_file, 'r')
    lines = src_f.readlines()
    src_f.close()

    sql = 'case '
    for line in lines[1:]:

        loc = line.split(',')
        sql += 'when latitude_fixed >= '  + str(float(loc[1]) - 0.0001) + ' and latitude_fixed <='   + str(float(loc[1]) + 0.0001) + ' and longitude_fixed >=' + str( float(loc[2]) - 0.0001) + ' and longitude_fixed <= ' + str(float(loc[2]) + 0.0001) + " then '" + loc[0].strip() + "' \n"
    sql += 'end as point'
    print(sql),

if __name__ == "__main__":
    src_file = r"D:\svc_touchpoint_seoul.code.latitude.longitude.csv"
    #dir_path = sys.argv
    parse(src_file)

