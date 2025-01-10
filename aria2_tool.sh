#!/usr/bin/env bash

# 保证本脚本创建的文件是 UTF-8 编码
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8

# 脚本绝对路径
SCRIPT_PATH="$(readlink -f "$0")"
# 脚本所在目录
BASE_DIR=$(dirname "${SCRIPT_PATH}")
# 会话文件路径
SESSION_PATH="${BASE_DIR}/aria2.session"
# 日志文件路径
LOG_PATH="${BASE_DIR}/aria2.log"
# 配置文件路径
CONF_PATH="${BASE_DIR}/aria2.conf"
# 程序名称
APP_NAME="aria2c"
# 程序路径
APP_PATH="${BASE_DIR}/${APP_NAME}"

# service 文件路径
SERVICE_PATH="/etc/systemd/system/aria2.service"

USER_AGENT="Transmission/4.0.6"
PEER_ID_PREFIX="-TR4060-"

GITHUB_PROXY="https://www.ghproxy.cn"

TRACKER_SOURCES=(
    'https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best_ip.txt'
    'https://raw.githubusercontent.com/DeSireFire/animeTrackerList/master/AT_best_ip.txt'
    'https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best.txt'
    'https://raw.githubusercontent.com/DeSireFire/animeTrackerList/master/AT_best.txt'
    'https://raw.githubusercontent.com/XIU2/TrackersListCollection/master/best.txt'
    'https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all_ip.txt'
    'https://raw.githubusercontent.com/DeSireFire/animeTrackerList/master/AT_all_ip.txt'
    'https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all_https.txt'
    'https://raw.githubusercontent.com/DeSireFire/animeTrackerList/master/AT_all_https.txt'
    'https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all_ws.txt'
    'https://raw.githubusercontent.com/DeSireFire/animeTrackerList/master/AT_all_ws.txt'
    'https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all_http.txt'
    'https://raw.githubusercontent.com/DeSireFire/animeTrackerList/master/AT_all_http.txt'
    'https://raw.githubusercontent.com/XIU2/TrackersListCollection/master/http.txt'
    'https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all_udp.txt'
    'https://raw.githubusercontent.com/DeSireFire/animeTrackerList/master/AT_all_udp.txt'
    'https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all.txt'
    'https://raw.githubusercontent.com/DeSireFire/animeTrackerList/master/AT_all.txt'
    'https://raw.githubusercontent.com/XIU2/TrackersListCollection/master/all.txt'
)

function save_session() {

    # 注意：-EOL 只能忽略 Tab，不会忽略空格，且结尾的 EOL 不能有空格
    local param="$(
        cat <<-EOL
	{
	    "jsonrpc": "2.0",
	    "method": "aria2.saveSession",
	    "id": "aria2_tool"
	}
	EOL
    )"

    local status=$(wget -q -T 1 -O - --post-data="${param}" 'http://127.0.0.1:6800/jsonrpc' | grep -e 'OK')
    if [ -z "${status}" ]; then
        echo 'call aria2.saveSession fail'
        return 1
    else
        echo 'call aria2.saveSession success'
        return 0
    fi
}

function pause_all() {

    # 注意：-EOL 只能忽略 Tab，不会忽略空格，且结尾的 EOL 不能有空格
    local param="$(
        cat <<-EOL
	{
	    "jsonrpc": "2.0",
	    "method": "aria2.pauseAll",
	    "id": "aria2_tool"
	}
	EOL
    )"

    local status=$(wget -q -T 1 -O - --post-data="${param}" 'http://127.0.0.1:6800/jsonrpc' | grep -e 'OK')
    if [ -z "${status}" ]; then
        echo 'call aria2.pauseAll fail'
        return 1
    else
        echo 'call aria2.pauseAll success'
        return 0
    fi
}

function unpause_all() {

    # 注意：-EOL 只能忽略 Tab，不会忽略空格，且结尾的 EOL 不能有空格
    local param="$(
        cat <<-EOL
	{
	    "jsonrpc": "2.0",
	    "method": "aria2.unpauseAll",
	    "id": "aria2_tool"
	}
	EOL
    )"

    local status=$(wget -q -T 1 -O - --post-data="${param}" 'http://127.0.0.1:6800/jsonrpc' | grep -e 'OK')
    if [ -z "${status}" ]; then
        echo 'call aria2.pauseAll fail'
        return 1
    else
        echo 'call aria2.pauseAll success'
        return 0
    fi
}

function shutdown() {

    # 注意：-EOL 只能忽略 Tab，不会忽略空格，且结尾的 EOL 不能有空格
    local param="$(
        cat <<-EOL
	{
	    "jsonrpc": "2.0",
	    "method": "aria2.shutdown",
	    "id": "aria2_tool"
	}
	EOL
    )"

    local status=$(wget -q -T 1 -O - --post-data="${param}" 'http://127.0.0.1:6800/jsonrpc' | grep -e 'OK')
    if [ -z "${status}" ]; then
        echo 'call aria2.shutdown fail'
        return 1
    else
        echo 'call aria2.shutdown success'
        return 0
    fi
}

function force_shutdown() {

    # 注意：-EOL 只能忽略 Tab，不会忽略空格，且结尾的 EOL 不能有空格
    local param="$(
        cat <<-EOL
	{
	    "jsonrpc": "2.0",
	    "method": "aria2.forceShutdown",
	    "id": "aria2_tool"
	}
	EOL
    )"

    local status=$(wget -q -T 1 -O - --post-data="${param}" 'http://127.0.0.1:6800/jsonrpc' | grep -e 'OK')
    if [ -z "${status}" ]; then
        echo 'call aria2.forceShutdown fail'
        return 1
    else
        echo 'call aria2.forceShutdown success'
        return 0
    fi
}

function change_tracker() {

    local trackers="${1}"

    # 注意：-EOL 只能忽略 Tab，不会忽略空格，且结尾的 EOL 不能有空格
    local param="$(
        cat <<-EOL
	{
	    "jsonrpc": "2.0",
	    "method": "aria2.changeGlobalOption",
	    "id": "aria2_tool",
	    "params": [
	        {
	            "bt-tracker": "${trackers}"
	        }
	    ]
	}
	EOL
    )"

    local status=$(wget -q -T 1 -O - --post-data="${param}" 'http://127.0.0.1:6800/jsonrpc' | grep -e 'OK')
    if [ -z "${status}" ]; then
        echo 'call aria2.changeGlobalOption fail'
        return 1
    else
        echo 'call aria2.changeGlobalOption success'
        return 0
    fi
}

function get_disk_type() {

    local download_dir="${1}"

    if [ -z "${download_dir}" ]; then
        return 0
    fi

    # 获取挂载点的设备名
    local device="$(df "${download_dir}" | awk 'NR==2 {print $1}')"
    if [ -z "${device}" ]; then
        return 0
    fi

    # 获取设备的基础名
    local base_device="$(basename "${device}")"
    if [ -z "${base_device}" ]; then
        return 0
    fi

    # 获取物理设备
    local physical_device="$(lsblk -no pkname "/dev/${base_device}")"
    if [[ "${physical_device}" == *"not a block device"* ]]; then
        return 0
    fi

    # 判断设备是否为 SSD 或 HDD
    local rotational=$(cat /sys/block/${physical_device}/queue/rotational)
    if [ ${rotational} -gt 0 ]; then
        return 1
    fi

    return 0
}

function config() {

    # 下载目录
    local download_dir="${1}"
    # tracker
    local trackers="${2}"

    # 若未指定参数，则从旧配置文件获取
    if [ -f "${CONF_PATH}" ]; then
        if [ -z "${download_dir}" ]; then
            download_dir="$(sed -n 's_^dir=__p' ${CONF_PATH})"
        fi
        if [ -z "${trackers}" ]; then
            trackers="$(sed -n 's_^bt-tracker=__p' ${CONF_PATH})"
        fi
    fi

    # 磁盘缓存，最小 16M，最大 1G
    local mems="$(free)"
    local index=$((0))
    local total=$((0))
    local cache='16'
    if [ -n "${mems}" ]; then
        for mem in $mems; do
            index=$((index + 1))
            if [ $index -eq 8 ]; then
                total=${mem}
                break
            fi
        done
    fi
    if [ ${total} -gt $((1024 * 2 * 1024)) ]; then
        cache='1024'
    elif [ ${total} -gt $((512 * 2 * 1024)) ]; then
        cache='512'
    elif [ ${total} -gt $((256 * 2 * 1024)) ]; then
        cache='256'
    elif [ ${total} -gt $((128 * 2 * 1024)) ]; then
        cache='128'
    elif [ ${total} -gt $((64 * 2 * 1024)) ]; then
        cache='64'
    elif [ ${total} -gt $((32 * 2 * 1024)) ]; then
        cache='32'
    fi

    local enable_mmap='false'
    local file_allocation='none'
    get_disk_type "${download_dir}"
    if [ $? != 0 ]; then
        enable_mmap='true'
        file_allocation='falloc'
    fi

    # 创建 session 文件
    if [ ! -f ${SESSION_PATH} ]; then
        touch ${SESSION_PATH}
        if [ $? != 0 ]; then
            echo "${SESSION_PATH} create fail, please try again"
            return 1
        fi
    fi

    # 注意：-EOL 只能忽略 Tab，不会忽略空格，且结尾的 EOL 不能有空格
    cat <<-EOL >"${CONF_PATH}"
	dir=${download_dir}
	input-file=${SESSION_PATH}
	log=${LOG_PATH}
	max-concurrent-downloads=50
	continue=true
	connect-timeout=10
	max-connection-per-server=16
	max-tries=0
	min-split-size=4M
	netrc-path=${BASE_DIR}/.netrc
	retry-wait=10
	server-stat-of=${BASE_DIR}/server.status
	server-stat-if=${BASE_DIR}/server.status
	split=16
	stream-piece-selector=geom
	timeout=10
	http-accept-gzip=true
	user-agent=${USER_AGENT}
	bt-detach-seed-only=true
	bt-enable-lpd=true
	bt-force-encryption=true
	bt-load-saved-metadata=true
	bt-max-peers=128
	bt-min-crypto-level=arc4
	bt-prioritize-piece=head
	bt-remove-unselected-file=true
	bt-require-crypto=true
	bt-request-peer-speed-limit=5
	bt-save-metadata=true
	bt-tracker=${trackers}
	bt-tracker-connect-timeout=10
	bt-tracker-timeout=10
	dht-entry-point=dht.transmissionbt.com:6881
	dht-entry-point6=dht.transmissionbt.com:6881
	dht-file-path=${BASE_DIR}/dht.dat
	dht-file-path6=${BASE_DIR}/dht6.dat
	dht-listen-port=6884
	enable-dht6=true
	follow-torrent=false
	listen-port=6991
	peer-id-prefix=${PEER_ID_PREFIX}
	peer-agent=${USER_AGENT}
	enable-rpc=true
	rpc-allow-origin-all=true
	rpc-listen-all=true
	rpc-listen-port=6800
	rpc-max-request-size=10M
	allow-piece-length-change=true
	always-resume=false
	auto-save-interval=20
	conf-path=${CONF_PATH}
	content-disposition-default-utf8=true
	daemon=true
	disk-cache=${cache}M
	enable-mmap=${enable_mmap}
	file-allocation=${file_allocation}
	force-save=true
	save-not-found=false
	log-level=notice
	summary-interval=0
	save-session=${SESSION_PATH}
	save-session-interval=20
	EOL
}

function install() {

    # 下载目录
    local download_dir="${1}"

    if [ -z "${download_dir}" ]; then
        download_dir="${BASE_DIR}/download"
    fi
    if [ ! -d "${download_dir}" ]; then
        mkdir -p "${download_dir}"
    fi

    local machine="$(uname -m)"
    if [ "x86_64" != "${machine}" ]; then
        echo "only support x86_64"
        return 1
    fi

    # 创建配置文件
    config "${download_dir}"
    if [ $? != 0 ]; then
        echo "${CONF_PATH} create fail, please try again"
        return 1
    fi

    # 注意：-EOL 只能忽略 Tab，不会忽略空格，且结尾的 EOL 不能有空格
    # 创建服务文件
    cat <<-EOL >"${SERVICE_PATH}"
	[Unit]
	Description=aria2
	After=network.target
	
	[Service]
	Type=forking
	ExecStart=/usr/bin/env bash ${SCRIPT_PATH} start
	ExecReload=/usr/bin/env bash ${SCRIPT_PATH} reload || /bin/echo "aria2 reload failed"
	ExecStop=/usr/bin/env bash ${SCRIPT_PATH} stop
	RestartSec=1
	TimeoutSec=0
	Restart=on-failure
	
	[Install]
	WantedBy=multi-user.target
	EOL

    if [ $? != 0 ]; then
        echo "${SERVICE_PATH} create fail, please try again"
        return 1
    fi

    systemctl daemon-reload
}

function uninstall() {

    systemctl stop aria2
    systemctl disable aria2

    # 删除服务文件
    rm -rf "${SERVICE_PATH}"
    # 删除日志文件
    rm -rf "${LOG_PATH}"

    systemctl daemon-reload
}

function auto_reload() {

    (
        crontab -l
        echo "0 8 * * * /bin/systemctl reload aria2 && /bin/systemctl restart aria2"
    ) | uniq | crontab -

    systemctl restart cron
}

function disable_auto_reload() {

    # 删除定时更新任务
    crontab -l | grep -v "/bin/systemctl reload aria2" | crontab -

    systemctl restart cron
}

function start() {

    local pidMsg="$(ps -ef | grep "${APP_NAME}" | grep -v grep)"
    if [ -n "${pidMsg}" ]; then
        echo "${APP_NAME} running, pid=${pidMsg}"
        return 0
    fi

    config

    if [ ! -f ${APP_PATH} ]; then
        echo "${APP_PATH} not exist"
        return 1
    fi
    if [ ! -x ${APP_PATH} ]; then
        chmod +x ${APP_PATH}
    fi
    if [ ! -x ${APP_PATH} ]; then
        echo "${APP_PATH} no permission"
        return 1
    fi
    if [ ! -f ${CONF_PATH} ]; then
        echo "${CONF_PATH} not exist"
        return 1
    fi

    ${APP_PATH} --conf-path=${CONF_PATH}

    if [ $? == 0 ]; then
        pidMsg="$(ps -ef | grep ${APP_NAME} | grep -v grep | awk '{print $2}')"
        if [ -n "${pidMsg}" ]; then
            auto_reload
            unpause_all
            echo "${APP_NAME} running, start success, pid=${pidMsg}"
            return 0
        fi

        echo "${APP_NAME} not running, start fail"
        return 1
    fi

    echo "${APP_NAME} start fail"
    return 1
}

function stop() {

    local pidMsg="$(ps -ef | grep ${APP_NAME} | grep -v grep | awk '{print $2}')"
    if [ -z "${pidMsg}" ]; then
        echo "${APP_NAME} not running, no need to stop"
        return 0
    fi

    save_session

    pause_all

    shutdown
    sleep 2
    pidMsg="$(ps -ef | grep ${APP_NAME} | grep -v grep | awk '{print $2}')"
    if [ -z "${pidMsg}" ]; then
        disable_auto_reload
        echo "${APP_NAME} not running, shutdown success"
        return 0
    fi

    force_shutdown
    sleep 2
    pidMsg="$(ps -ef | grep ${APP_NAME} | grep -v grep | awk '{print $2}')"
    if [ -z "${pidMsg}" ]; then
        disable_auto_reload
        echo "${APP_NAME} not running, force shutdown success"
        return 0
    fi

    ps -ef | grep ${APP_NAME} | grep -v grep | awk '{print $2}' | xargs kill
    sleep 2
    pidMsg="$(ps -ef | grep ${APP_NAME} | grep -v grep | awk '{print $2}')"
    if [ -n "${pidMsg}" ]; then
        echo "${APP_NAME} still running, stop fail, pid=${pidMsg}"
        return 1
    fi

    disable_auto_reload
    echo "${APP_NAME} not running, stop success"
    return 0
}

function status() {

    local pidMsg="$(ps -ef | grep ${APP_NAME} | grep -v grep | awk '{print $2}')"
    if [ -n "${pidMsg}" ]; then
        echo "${APP_NAME} running, pid=${pidMsg}"
    else
        echo "${APP_NAME} not running"
    fi
}

function reload() {

    local tracker_array=()

    local total_tracker=$((0))
    local repeat_tracker=$((0))
    local valid_tracker=$((0))

    for url in ${TRACKER_SOURCES[@]}; do
        echo "tracker source: ${url}"

        local content="$(wget -q -T 1 -O - ${url})"
        if [ -z "${content}" ]; then
            content="$(wget -q -T 2 -O - ${GITHUB_PROXY}/${url})"
        fi
        if [ -z "${content}" ]; then
            echo "tracker source invalid: ${GITHUB_PROXY}/${url}"
            continue
        fi

        for str in ${content}; do
            if [ -z "${str}" ]; then
                continue
            fi

            str="$(echo -n ${str} | sed 's_udp://_ udp://_g' | sed 's_http://_ http://_g' |
                sed 's_https://_ https://_g' | sed 's_wss://_ wss://_g' | sed 's_ws://_ ws://_g')"

            for str_tracker in ${str}; do
                if [ -z "${str_tracker}" ]; then
                    continue
                fi

                str_tracker="$(echo -n ${str_tracker} | sed 's_\\t__g' | sed 's_\\r__g' | sed 's_\\n__g' |
                    sed 's_announce"_announce_g' | sed 's_announce+_announce_g' | sed 's_announce-_announce_g' |
                    sed 's_ __g')"
                if [ -z "${str_tracker}" ]; then
                    continue
                fi

                if [ -z "$(echo -n ${str_tracker}) | grep -ie '^udp://*')" \
                    -a -z "$(echo -n ${str_tracker}) | grep -ie '^http://*')" \
                    -a -z "$(echo -n ${str_tracker}) | grep -ie '^https://*')" \
                    -a -z "$(echo -n ${str_tracker}) | grep -ie '^wss://*')" \
                    -a -z "$(echo -n ${str_tracker}) | grep -ie '^ws://*')" ]; then
                    continue
                fi

                total_tracker=$((total_tracker + 1))

                local exist=$((0))
                for tracker in ${tracker_array[@]}; do
                    if [ ${str_tracker} == ${tracker} ]; then
                        exist=$((1))
                        break
                    fi
                done

                if [ ${exist} == 1 ]; then
                    repeat_tracker=$((repeat_tracker + 1))
                    continue
                fi

                tracker_array[valid_tracker]=${str_tracker}
                valid_tracker=$((valid_tracker + 1))
            done
        done
    done

    echo "total_tracker: ${total_tracker}, repeat_tracker: ${repeat_tracker}, valid_tracker: ${valid_tracker}"

    if [ ${valid_tracker} -le 0 ]; then
        echo "no valid tracker, reload fail"
        return 1
    fi
    if [ ${valid_tracker} -le 500 ]; then
        echo "valid tracker not enough, reload fail"
        return 1
    fi

    local tracker_all_str=''
    local index=$((1))

    for tracker in ${tracker_array[@]}; do
        if [ ${index} -le 1 ]; then
            tracker_all_str="${tracker}"
        else
            tracker_all_str="${tracker_all_str},${tracker}"
        fi
        index=$((index + 1))
    done

    config "" "${tracker_all_str}"

    local pidMsg="$(ps -ef | grep ${APP_NAME} | grep -v grep | awk '{print $2}')"
    if [ -z "${pidMsg}" ]; then
        return 0
    fi

    save_session

    change_tracker "${tracker_all_str}"

    save_session
}

case "${1}" in
'install')
    install "${2}"
    ;;
'uninstall')
    uninstall
    ;;
'start')
    start
    ;;
'stop')
    stop
    ;;
'status')
    status
    ;;
'reload')
    reload
    ;;
'restart')
    stop
    start
    ;;
'auto_reload')
    auto_reload
    ;;
'disable_auto_reload')
    disable_auto_reload
    ;;
*)
    echo "usage: ${SCRIPT_PATH} install|uninstall|start|stop|status|reload|restart|auto_reload|disable_auto_reload"
    ;;
esac
