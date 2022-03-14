#! /bin/bash

sudo mysql <<EOF
CREATE DATABASE name;
USE name;
CREATE TABLE namet (fname VARCHAR(100), lname VARCHAR(100), dob DATE);
INSERT INTO namet VALUES("Mark","Krishnan","1996-12-13"),("Shivram","Krishnan","1998-08-29");
SELECT fname,lname,dob from namet;
DROP TABLE namet;
EOF
