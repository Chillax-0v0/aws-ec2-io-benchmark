[global]
direct=1
ioengine=libaio
numjobs=1
runtime=60
group_reporting
filename=/dev/nvme1n1

[throughput]
iodepth=64
rw=write
bs=1024k
name=Write_PPS_Testing
stonewall

[iops]
iodepth=128
rw=randwrite
bs=4k
name=Rand_Write_Testing
stonewall
