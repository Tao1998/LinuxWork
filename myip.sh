#!/bin/bash
start_time=`date +%s` #定义脚本运行的开始时间
echo "检查同一网段ip地址是否网络联通" 

# 获取IP和子网掩码
#myip=`ifconfig | grep ^en -A9 | grep inet -w | awk '{print $2}'`
#mask=`ifconfig | grep ^en -A9 | grep inet -w | awk '{print $4}'`
#myip=`ifconfig | grep ^wl -A9 | grep inet -w | awk '{print $2}'`
#mask=`ifconfig | grep ^wl -A9 | grep inet -w | awk '{print $4}'`

myip=(`ifconfig | grep broadcast -wC0 | grep inet -w | awk '{print $2}' | grep -Eo "[0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]" | awk '{print $1}'`)
mask=(`ifconfig | grep broadcast -wC0 | grep inet -w | awk '{print $4}' | grep -Eo "[0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]" | awk '{print $1}'`)


echo "myip = "${myip[0]}.${myip[1]}.${myip[2]}.${myip[3]}
echo "mask = "${mask[0]}.${mask[1]}.${mask[2]}.${mask[3]}

# 计算子网
for i in $(seq 0 3)
do
	subnet[$i]=$[myip[$i]&mask[$i]]
done
echo "subnet = "${subnet[0]}.${subnet[1]}.${subnet[2]}.${subnet[3]}

# 掩码可能的数值
masknum[0]=0
for i in $(seq 0 7)
do
	masknum[$(($i+1))]=$((${masknum[$i]}+2**(7-$i)))
done

# 测试子网掩码是否正确
for var in ${mask[@]}
do
	echo "${masknum[@]}" | grep -wq "$var" || echo "掩码有误！不在${masknum[@]}中"
done

for i in $(seq 0 2)
do
	test ${mask[$i]} -ge ${mask[$(($i+1))]} || echo "掩码有误！高位应大于等于低位"
done

# 不等于255的索引
for i in $(seq 0 3)
do
	if test ${mask[$((3-$i))]} -ne 255
	then
		maskneq255=$[3-$i] # 不等于255的索引
	fi
done



[ -e /tmp/fd1 ] || mkfifo /tmp/fd1 #创建有名管道
exec 3<>/tmp/fd1 #创建文件描述符，以可读（<）可写（>）的方式关联管道文件，这时候文件描述符3就有了有名管道文件的所有特性
rm -rf /tmp/fd1 #关联后的文件描述符拥有管道文件的所有特性,所以这时候管道文件可以删除，我们留下文件描述符来用就可以了
for ((i=1;i<=200;i++))
do
echo >&3 #&3代表引用文件描述符3，这条命令代表往管道里面放入了一个"令牌"
done

if [ $maskneq255 == 2 ]
then
	for ip2 in $(seq 0 $[255-${mask[2]}])
	do
		for ((ip3=0;ip3<=255;ip3++))
		do
			if [ $ip2 != $[255-${mask[2]}] -o $ip3 != 255  ] && [ $ip2 != 0 -o $ip3 != 0 ]
			then
			read -u3 #代表从管道中读取一个令牌
			{
				ping ${subnet[0]}.${subnet[1]}.$[${subnet[2]}+$ip2].$ip3 -c3w2 | grep "ttl=" | awk '{print $7}' | tr -cd "[0-9.\n]" | awk '{sum+=$1}END{if(NR==0){print '${subnet[0]}'"."'${subnet[1]}'"."'$[${subnet[2]}+$ip2]'"."'$ip3' >> "./disconneted.txt"}else {print '${subnet[0]}'"."'${subnet[1]}'"."'$[${subnet[2]}+$ip2]'"."'$ip3'" Avg="sum/NR >> "./connected.txt"};}'
				echo >&3 #代表我这一次命令执行到最后，把令牌放回管道
			}&
			fi
		done
	done
elif [ $maskneq255 == 3 ] 
then	
	for ip3 in $(seq 0 $[255-${mask[3]}])
	do
		if [ $ip3 != $[255-${mask[3]}] ] && [ $ip3 != 0 ]
		then
		read -u3 #代表从管道中读取一个令牌
		{
			ping ${subnet[0]}.${subnet[1]}.${subnet[2]}.$[${subnet[3]}+$ip3] -c3w2 | grep "ttl=" | awk '{print $7}' | tr -cd "[0-9.\n]" | awk '{sum+=$1}END{if(NR==0){print '${subnet[0]}'"."'${subnet[1]}'"."'${subnet[2]}'"."'$[${subnet[3]}+$ip3]' >> "./disconneted.txt"}else {print '${subnet[0]}'"."'${subnet[1]}'"."'${subnet[2]}'"."'$[${subnet[3]}+$ip3]'" Avg="sum/NR >> "./connected.txt"};}'
			echo >&3 #代表我这一次命令执行到最后，把令牌放回管道
		}&
		fi
	done
else
	echo "只有一个本机ip"
fi	

wait

stop_time=`date +%s` #定义脚本运行的结束时间

echo "TIME:`expr $stop_time - $start_time`"
exec 3<&- #关闭文件描述符的读
exec 3>&- #关闭文件描述符的写

# 排序
sort -t'.' -k1n,1 -k2n,2 -k3n,3 -k4n,4 disconneted.txt > disconnetedSortByIP.txt
sort -t'=' -k2g connected.txt > connectedSortByTime.txt
