#!/bin/sh
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
	arm*)
		install_packages $bit
		;;
	aarch64)
		install_packages $bit
		;;
	*)
	    echo "[ERROR] 不支持的系统类型 $arch ($bit bit), 程序仍然会尝试安装"
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
	echo "[INFO] 开始获取甜糖自动重启脚本"
	wget --no-check-certificate -O /usr/node/crash_monitor.sh https://cdn.jsdelivr.net/gh/ShallowAi/ttnode@main/bin/crash_monitor.sh
	chmod a+x /usr/node/*
	echo "[INFO] 创建甜糖日志文件."
	touch /usr/node/log.log
	echo "[INFO] 获取基础软件包, 并更新软件源."
	case $os_type in
	*Debian*)
		apt -y install qrencode
		;;
	*Ubuntu*)
		apt -y install qrencode
		;;
	*CentOS*)
		yum update
		yum -y install qrencode
		;;
	*)
		echo "[ERROR] 似乎不支持这个系统, 也有可能是尚未适配."
		echo "[WARN] 未适配的系统在结束时可能不会显示二维码. 会在后续修复."
		read -s -n1 -p "[WARN] 继续吗? 按任意键继续, 按 Ctrl+C 退出."
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
	echo "[INFO] 开始创建并检测分区."
	read -s -n1 -p "[WARN] 当前操作会覆盖开机启动文件, 按任意键继续, 按 Ctrl+C 退出."
	if [ "$(blkid /dev/sda1)" != "" ]
	then
		echo "#!/bin/sh -e" > /etc/rc.local
		echo "mount /dev/sda1 /mnts" >> /etc/rc.local
		echo "exit 0" >> /etc/rc.local
		mount /dev/sda1 /mnts
		echo "[INFO] 存储设备 sda1 挂载完成."
	else
		echo "[ERROR] sda1 不存在, 尝试挂载 SD卡."
			if [ "$(blkid /dev/mmcblk0p1)" != "" ]
			then
				echo "#!/bin/sh -e" > /etc/rc.local
				echo "mount /dev/mmcblk0p1 /mnts" >> /etc/rc.local
				echo "exit 0" >> /etc/rc.local
				mount /dev/mmcblk0p1 /mnts
				echo "[INFO] 存储设备 mmcblk0p1 挂载完成."
			elif [ "$(blkid /dev/mmcblk1p1)" != "" ]
			then
				read -s -n1 -p "[WARN] 当前正在挂载 mmcblk1p1 部分设备中该设备为内置存储, 请注意! 按任意键继续, 按 Ctrl+C 退出."
				echo "#!/bin/sh -e" > /etc/rc.local
				echo "mount /dev/mmcblk1p1 /mnts" >> /etc/rc.local
				echo "exit 0" >> /etc/rc.local
				mount /dev/mmcblk1p1 /mnts
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

dns_change(){
	echo "nameserver 119.29.29.29" > /etc/resolv.conf
	echo "nameserver 119.29.29.29" > /etc/resolvconf/resolv.conf.d/head
}

# Mac 地址修改函数
# 第一字节必须为偶数
mac_modify(){
	echo "[INFO] 开始修改 MAC 地址."
	sed -i "6a\hwaddress ether 00:$(openssl rand -hex 5 | cut --output-delimiter=: -b 1-2,3-4,5-6,7-8,9-10)" /etc/network/interfaces
}

dis_swap(){
	sed -i "s/vm.swappiness=(\d)+/vm.swappiness=0/g" /etc/sysctl.conf
}

printf "%-50s\n" "-" | sed 's/\s/-/g'
echo
echo "Author: ShallowAi"
echo "Blog: swai.top"
echo "Email: Shallowlovest@qq.com"
echo "甜糖邀请码: 451003"
echo
printf "%-50s\n" "-" | sed 's/\s/-/g'
echo "欢迎使用甜糖一键部署脚本 Dev版本, 正在检测系统架构并准备相关文件..."
read -s -n1 -p "按任意键开始安装..."
dns_change
check_arch
fstab_mount
crontab_add
mac_modify
run_ttnode
echo
echo "已完成安装! 感谢您的使用, 支持我 Email: Shallowlovest@qq.com 甜糖邀请码: 451003"