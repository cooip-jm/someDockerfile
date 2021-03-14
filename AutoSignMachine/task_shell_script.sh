#!/bin/sh
set -e

if [ $1 ]; then
	echo "更换为清华大学的源..."
	sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories
	echo "容器启动，补充安装一些系统组件包..."
	apk add perl openssl libjpeg-turbo-dev libpng-dev libtool libgomp tesseract-ocr graphicsmagick
	echo "npm更换为淘宝镜像源"
	npm config set registry http://registry.npm.taobao.org/
fi

echo "更新仓库代码..."
cd /AutoSignMachine
git reset --hard
echo "git pull拉取最新代码..."
git -C /AutoSignMachine pull --rebase
git checkout azmodan
echo "npm install 安装最新依赖..."
npm install --loglevel error --prefix /AutoSignMachine

mergedListFile="/AutoSignMachine/merged_list_file.sh"
envFile="/root/.AutoSignMachine/.env"
echo "定时任务文件路径为 ${mergedListFile}"
echo '' >${mergedListFile}

if [ $ENABLE_52POJIE ]; then
	echo "10 13 * * * sleep \$((RANDOM % 120)); node /AutoSignMachine/index.js 52pojie --htVD_2132_auth=${htVD_2132_auth} --htVD_2132_saltkey=${htVD_2132_saltkey} >> /logs/52pojie.log 2>&1 &" >>${mergedListFile}
else
	echo "未配置启用52pojie签到任务环境变量ENABLE_52POJIE，故不添加52pojie定时任务..."
fi

if [ $ENABLE_BILIBILI ]; then
	echo "*/30 7-22 * * * sleep \$((RANDOM % 120)); node /AutoSignMachine/index.js bilibili --username ${BILIBILI_ACCOUNT} --password ${BILIBILI_PWD} >> /logs/bilibili.log 2>&1 &" >>${mergedListFile}
else
	echo "未配置启用bilibi签到任务环境变量ENABLE_BILIBILI，故不添加Bilibili定时任务..."
fi

if [ $ENABLE_IQIYI ]; then
	echo "*/30 7-22 * * * sleep \$((RANDOM % 120)); node /AutoSignMachine/index.js iqiyi --P00001 ${P00001} --P00PRU ${P00PRU} --QC005 ${QC005}  --dfp ${dfp} >> /logs/iqiyi.log 2>&1 &" >>${mergedListFile}
else
	echo "未配置启用iqiyi签到任务环境变量ENABLE_IQIYI，故不添加iqiyi定时任务..."
fi

if [ $ENABLE_UNICOM ]; then
	if [ -f $envFile ]; then
		cp -f $envFile /AutoSignMachine/config/.env
		if [ $UNICOM_JOB_CONFIG ]; then
			echo "找到联通细分任务配置故拆分，针对每个任务增加定时任务"
			minute=0
			hour=8
			job_interval=6
			for job in $(paste -d" " -s - <$UNICOM_JOB_CONFIG); do
				echo "$minute $hour * * * sleep \$((RANDOM % 60)); node /AutoSignMachine/index.js unicom --tryrun --tasks $job >>/logs/unicom_$job.log 2>&1 &" >>${mergedListFile}
				minute=$(expr $minute + $job_interval)
				if [ $minute -ge 60 ]; then
					minute=0
					hour=$(expr $hour + 1)
				fi
			done
		else
			echo "*/10 6-23 * * * sleep \$((RANDOM % 120)); node /AutoSignMachine/index.js unicom >> /logs/unicom.log 2>&1 &" >>${mergedListFile}
		fi
	else
		echo "未找到 .env配置文件，故不添加unicom定时任务。"
	fi
#     if [ -f $UNICOM_CONFIG ]; then
#         if type jq >/dev/null 2>&1; then
#             echo "jq已存在"
#         else
#             echo "安装jq"
#             apk add jq
#         fi
#         for accountSn  in `cat ${UNICOM_CONFIG} | jq -r .accountSn | sed 's/,/ /g'`
#         do
#             echo "*/30 7-22 * * * sleep \$((RANDOM % 120)); node /AutoSignMachine/index.js unicom --accountSn $accountSn  --config ${UNICOM_CONFIG} >> /AutoSignMachine/logs/unicom${accountSn}.log 2>&1 &" >>${mergedListFile}
#         done
#     else
#         echo "*/30 7-22 * * * sleep \$((RANDOM % 120)); node /AutoSignMachine/index.js unicom --user ${UNICOM_PHONE} --password ${UNICOM_PWD} --appid ${UNICOM_APPID} >> /AutoSignMachine/logs/unicom.log 2>&1 &" >>${mergedListFile}
#     fi
#     ##兑换流量包脚本环境配置
#     if [ $ACTIVE_FLOW ]; then
#         if type bash >/dev/null 2>&1; then
#             echo "已安装 bash "
#         else
#             echo "安装bash"
#             apk add bash
#         fi
#         if type openssl >/dev/null 2>&1; then
#             echo "已安装 openssl "
#         else
#             echo "安装openssl"
#             apk add openssl
#         fi
#         if type curl >/dev/null 2>&1; then
#             echo "已安装 curl "
#         else
#             echo "安装curl"
#             apk add curl
#         fi
#     fi
else
	echo "未配置启用unicom签到任务环境变量ENABLE_UNICOM，故不添加unicom定时任务..."
fi

echo "增加默认脚本更新任务..."
echo "21 */1 * * * docker_entrypoint.sh >> /logs/default_task.log 2>&1" >>$mergedListFile

echo "判断是否配置自定义shell执行脚本..."
if [ 0"$CUSTOM_SHELL_FILE" = "0" ]; then
	echo "未配置自定shell脚本文件，跳过执行。"
else
	if expr "$CUSTOM_SHELL_FILE" : 'http.*' &>/dev/null; then
		echo "自定义shell脚本为远程脚本，开始下在自定义远程脚本。"
		wget -O /jds/shell_script_mod.sh $CUSTOM_SHELL_FILE
		echo "下载完成，开始执行..."
		echo "#远程自定义shell脚本追加定时任务" >>$mergedListFile
		sh /jds/shell_script_mod.sh
		echo "自定义远程shell脚本下载并执行结束。"
	else
		if [ ! -f $CUSTOM_SHELL_FILE ]; then
			echo "自定义shell脚本为docker挂载脚本文件，但是指定挂载文件不存在，跳过执行。"
		else
			echo "docker挂载的自定shell脚本，开始执行..."
			echo "#docker挂载自定义shell脚本追加定时任务" >>$mergedListFile
			sh $CUSTOM_SHELL_FILE
			echo "docker挂载的自定shell脚本，执行结束。"
		fi
	fi
fi

echo "判断是否配置了随即延迟参数..."
if [ $RANDOM_DELAY_MAX ]; then
	if [ $RANDOM_DELAY_MAX -ge 1 ]; then
		echo "已设置随机延迟为 $RANDOM_DELAY_MAX , 设置延迟任务中..."
		sed -i "/node/sleep \$((RANDOM % \$RANDOM_DELAY_MAX)) && node/g" $mergedListFile
	fi
else
	echo "未配置随即延迟对应的环境变量，故不设置延迟任务..."
fi

echo "增加 |ts 任务日志输出时间戳..."
sed -i "/\( ts\| |ts\|| ts\)/!s/>>/\|ts >>/g" $mergedListFile

echo "加载最新的定时任务文件..."
crontab $mergedListFile
