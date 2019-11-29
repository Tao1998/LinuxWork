# LinuxWork
 shell for Linux

### 题目：

**完成一个shell程序，依次实现以下功能：**

* **检验自己主机所在的网段有多少主机连通**
* **获取各个连通主机的连接响应时间，并对响应时间进行排序**

### **代码思路：**

1.	**根据ifconfig结果由grep和awk组合获取ip和mask并存为数组；**
	*	如，ip为10.132.6.127，mask为255.255.128.0，则数组myip为（10 132 6 127）即myip[0]=10，myip[1]=132，myip[2]=6，myip[3]=127，mask同理
2.	**计算子网号，得到数组subnet**
	1.	对myip和mask相同索引的元素相与”&”
	    * 如，ip为10.132.6.127，mask为255.255.128.0，则subnet[0]=myip[0]&mask[0]，故数组subnet为（10 132 6 0）即subnet [0]=10，subnet [1]=132，subnet [2]=6，subnet [3]=0
3.	**构造masknum数组存放子网掩码中可能出现的数值，即 0，128，192，224，240，248，252，254，255**
4.	**找到mask数组中不等于255的索引，将最大的索引存为maskneq255**
    *  如，mask为255.255.128.0，则maskneq255=2
5.	**根据maskneq255对同一网段中的ip使用ping测试，这一过程使用有名管道和多线程进行加速**
	1.	当maskneq255=2时，同一网段的ip为subnet[0].subnet[1].subnet[2].1到subnet[0].subet[1].subnet[2]+255-mask[2].254（跳过广播地址）
	    * 如，ip为10.132.6.127，mask为255.255.128.0，subnet为10.132.0.0，需要ping的IP为10.132.0.1~10.132.127.254
    2.	当maskneq255=3时，同一网段的ip为subnet[0].subnet[1].subnet[2].subnet[3]到subnet[0].subet[1].subnet[2].subnet[3]+255-mask[3]-1（跳过广播地址）
	    * 如，ip为10.132.6.130，mask为255.255.255.128，subnet为10.132.6.128，需要ping的IP为10.132.6.129~10.132.6.254
    3. 每个ip 进行3次ping，使用awk计算平均响应时间，如果连通则将ip和平均响应时间重定向到connected.txt，如果不连通则将ip重定向到disconnected.txt
6.	**使用sort对connected.txt进行排序，按照平均响应时间升序排列并重定向到connectedSortByTime**
7.	**使用sort对disconnected.txt进行排序，按照ip升序排列并重定向到disconnectedSortByIP**

### 源代码
* [myip.sh](/myip.sh)
