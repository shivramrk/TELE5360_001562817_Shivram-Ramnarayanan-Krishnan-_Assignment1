 
#!/bin/bash
echo "Kernel Number"
hostnamectl | grep Kernel
echo "*************************************************************************"
echo "Bash Version"

bash --version
echo "*************************************************************************"
echo "Free Storage"
df
echo "*************************************************************************"
echo "Free Memory"
free -h
echo "*************************************************************************"
echo "No of files in pwd"
ls -l /home/sk98/Desktop|wc -l
echo "*************************************************************************"
echo "IP address"
hostname -i
echo "*************************************************************************"
echo "Interfaces"
ifconfig -a




