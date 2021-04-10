#!/bin/sh
set -e

mergedListFile="/scripts/docker/merged_list_file.sh"

echo "附加功能1，使用jds仓库的gen_code_conf.list文件"
cp /jds/jd_scripts/gen_code_conf.list "$GEN_CODE_LIST"

echo "附加功能2，拉取monk-coder仓库的代码，并增加相关任务"
if [ ! -d "/monk/" ]; then
  echo "未检查到monk-coder仓库脚本，初始化下载相关脚本..."
  cp -rf /local_scripts/monk/ /monk
#   git clone https://github.com/monk-coder/dust /monk
else
  echo "更新monk-coder脚本相关文件..."
#   git -C /monk reset --hard
#   git -C /monk pull --rebase
fi

if [ -n "$(ls /monk/car/*_*.js)" ]; then
  cp -f /monk/car/*_*.js /scripts
fi
if [ -n "$(ls /monk/i-chenzhe/*_*.js)" ]; then
  cp -f /monk/i-chenzhe/*_*.js /scripts
fi
if [ -n "$(ls /monk/member/*_*.js)" ]; then
  cp -f /monk/member/*_*.js /scripts
fi
if [ -n "$(ls /monk/normal/*_*.js)" ]; then
  cp -f /monk/normal/*_*.js /scripts
fi
cat /monk/i-chenzhe/remote_crontab_list.sh /monk/remote_crontab_list.sh >>"$mergedListFile"
echo "替换node使用spnode执行任务"
sed -i "s/node/spnode/g" "$mergedListFile"
sed -i "/\(jd_carnivalcity.js\|jd_car_exchange.js\)/s/spnode/spnode conc/g" "$mergedListFile"

echo "附加功能3，惊喜工厂参团"
sed -i "s/https:\/\/gitee.com\/shylocks\/updateTeam\/raw\/main\/jd_updateFactoryTuanId.json/https:\/\/raw.githubusercontent.com\/iouAkira\/updateGroup\/master\/shareCodes\/jd_updateFactoryTuanId.json/g" /scripts/jd_dreamFactory.js
sed -i "s/https:\/\/raw.githubusercontent.com\/LXK9301\/updateTeam\/master\/jd_updateFactoryTuanId.json/https:\/\/raw.githubusercontent.com\/iouAkira\/updateGroup\/master\/shareCodes\/jd_updateFactoryTuanId.json/g" /scripts/jd_dreamFactory.js
sed -i "s/https:\/\/gitee.com\/lxk0301\/updateTeam\/raw\/master\/shareCodes\/jd_updateFactoryTuanId.json/https:\/\/raw.githubusercontent.com\/iouAkira\/updateGroup\/master\/shareCodes\/jd_updateFactoryTuanId.json/g" /scripts/jd_dreamFactory.js
sed -i "s/\(.*\/\/.*joinLeaderTuan.*\)/   await joinLeaderTuan();/g" /scripts/jd_dreamFactory.js
sed -i "s/6S9y4sJUfA2vPQP6TLdVIQ==/MUdRsCXI13_DDYMcnD8v7g==/g" /scripts/jd_dreamFactory.js
