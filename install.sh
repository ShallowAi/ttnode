#!/bin/bash
#
# 甜糖一键部署脚本
#
# Copyright (C) 2019-2021 @ShallowAi
#
# Blog: swai.top
#

check_arch(){
	arch=`uname -m`
	bit=`getconf LONG_BIT`
	case $arch in
	armv7l)
		install_packages $bit
		;;
	armv7)
		install_packages $bit
		;;
	armv8)
		install_packages $bit
		;;
	arm64)
		install_packages $bit
		;;
	aarch64)
		install_packages $bit
		;;
	*)
	    echo "不支持的系统类型 $arch ($bit bit)"
		;;
	esac
}

install_packages(){
    os_type=`cat /etc/os-release`
	mkdir /usr/node
	echo "[INFO] 开始获取甜糖核心程序."
	if [ $1 = 32 ]
	then
		wget --no-check-certificate -O /usr/node/ttnode https://cdn.jsdelivr.net/gh/ShallowAi/ttnode@main/bin/ttnode_32
	else
		wget --no-check-certificate -O /usr/node/ttnode https://cdn.jsdelivr.net/gh/ShallowAi/ttnode@main/bin/ttnode
	fi
	chmod a+x /usr/node/ttnode
	echo "[INFO] 开始获取甜糖自动重启脚本"
	wget --no-check-certificate -O /usr/node/crash_monitor.sh https://cdn.jsdelivr.net/gh/ShallowAi/ttnode@main/bin/crash_monitor.sh
	echo "[INFO] 创建甜糖日志文件."
	touch /usr/node/log.log
	echo "[INFO] 获取基础软件包, 并更新软件源."
	case $os_type in
	*Debian*)
		debian_modify
		apt -y install qrencode
		;;
	*Ubuntu*)
		apt update
		apt -y install qrencode
		;;
	*CentOS*)
		yum update
		yum -y install qrencode
		;;
	*)
		echo "[ERROR] 似乎不支持这个系统, 也有可能是尚未适配, 将会继续安装."
		apt -y install qrencode
		;;
	esac
}

debian_modify(){
	cp /etc/apt/sources.list /etc/apt/sources.list.bak
	cp /etc/apt/sources.list.d/armbian.list /etc/apt/sources.list.d/armbian.list.bak
	echo "[INFO] 已完成软件源备份."
	cat /etc/apt/sources.list | sed 's/http.*\/debian/http:\/\/mirrors.tuna.tsinghua.edu.cn\/debian/g' | cat > /etc/apt/sources.list
	cat /etc/apt/sources.list.d/armbian.list | sed 's/http.*\/armbian/http:\/\/mirrors.tuna.tsinghua.edu.cn\/armbian/g' | cat > /etc/apt/sources.list.d/armbian.list
	apt update
}

fstab_mount(){
	mkdir /mnts
	echo "[INFO] 开始创建并检测分区表."
	if [ "$(blkid /dev/sda1)" != "" ]
	then
		echo "/dev/sda1 /mnts ext4 defaults 0 0" >> /etc/fstab
		mount /dev/sda1 /mnts
		mount -a
		echo "[INFO] 存储设备 sda1 挂载完成."
	else
		echo "[ERROR] sda1 不存在, 尝试挂载 SD卡."
			if [ "$(blkid /dev/mmcblk0p1)" != "" ]
			then
				echo "/dev/mmcblk0p1 /mnts ext4 defaults 0 0" >> /etc/fstab
				mount /dev/mmcblk0p1 /mnts
				mount -a
				echo "[INFO] 存储设备 mmcblk0p1 挂载完成."
			else
				echo "[ERROR] 无存储设备可用, 异常退出."
				exit 1
			fi
	fi
}

crontab_add(){
	crontab -l | { cat; echo "* * * * * /usr/node/crash_monitor.sh"; } | crontab
}

run_ttnode(){
	echo "[INFO] 开始运行甜糖星愿服务."
	/usr/node/ttnode -p /mnts | grep uid | sed -e 's/^.*uid = //g' -e 's/.\s//g' | tr -d '\n' | qrencode -o - -t UTF8
	echo "恭喜! 若无报错, 甜糖星愿服务即已运行, 扫描上述二维码即可添加设备!"
}

printf "%-50s\n" "-" | sed 's/\s/-/g'
echo
echo "Author: ShallowAi"
echo "Blog: swai.top"
echo "Email: Shallowlovest@qq.com"
echo "甜糖邀请码: 451003"
echo
printf "%-50s\n" "-" | sed 's/\s/-/g'
echo "欢迎使用甜糖一键部署脚本, 正在检测系统架构并准备相关文件..."
read -s -n1 -p "按任意键开始安装..."
check_arch
fstab_mount
crontab_add
run_ttnode
echo
echo "已完成安装! 感谢您的使用, 支持我 Email: Shallowlovest@qq.com 甜糖邀请码: 451003"