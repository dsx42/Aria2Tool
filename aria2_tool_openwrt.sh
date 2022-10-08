#!/bin/sh

# import json support
. /usr/share/libubox/jshn.sh

save_session() {
    status=$(wget -q -T 1 -O - 'http://127.0.0.1:6800/jsonrpc?jsonrpc=2.0&method=aria2.saveSession&id=aria2_tool' |
        grep -e 'OK')
    if [ -z "${status}" ]; then
        echo ''
        echo 'call aria2.saveSession fail'
    else
        echo ''
        echo 'call aria2.saveSession success'
    fi
}

shutdown() {
    status=$(wget -q -T 1 -O - 'http://127.0.0.1:6800/jsonrpc?jsonrpc=2.0&method=aria2.shutdown&id=aria2_tool' |
        grep -e 'OK')
    if [ -z "${status}" ]; then
        echo ''
        echo 'call aria2.shutdown fail'
    else
        echo ''
        echo 'call aria2.shutdown success'
    fi
}

force_shutdown() {
    status=$(wget -q -T 1 -O - 'http://127.0.0.1:6800/jsonrpc?jsonrpc=2.0&method=aria2.forceShutdown&id=aria2_tool' |
        grep -e 'OK')
    if [ -z "${status}" ]; then
        echo ''
        echo 'call aria2.forceShutdown fail'
    else
        echo ''
        echo 'call aria2.forceShutdown success'
    fi
}

update_tracker() {

    content="$(opkg list-installed aria2)"
    if [ -z "${content}" ]; then
        echo ''
        echo 'Aria2 not installed, update Tracker fail'
        return
    fi

    github_proxy='https://ghproxy.com'

    sources='
        https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best_ip.txt
        https://raw.githubusercontent.com/DeSireFire/animeTrackerList/master/AT_best_ip.txt
        https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best.txt
        https://raw.githubusercontent.com/DeSireFire/animeTrackerList/master/AT_best.txt
        https://raw.githubusercontent.com/XIU2/TrackersListCollection/master/best.txt
        https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all_ip.txt
        https://raw.githubusercontent.com/DeSireFire/animeTrackerList/master/AT_all_ip.txt
        https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all_https.txt
        https://raw.githubusercontent.com/DeSireFire/animeTrackerList/master/AT_all_https.txt
        https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all_ws.txt
        https://raw.githubusercontent.com/DeSireFire/animeTrackerList/master/AT_all_ws.txt
        https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all_http.txt
        https://raw.githubusercontent.com/DeSireFire/animeTrackerList/master/AT_all_http.txt
        https://raw.githubusercontent.com/XIU2/TrackersListCollection/master/http.txt
        https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all_udp.txt
        https://raw.githubusercontent.com/DeSireFire/animeTrackerList/master/AT_all_udp.txt
        https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all.txt
        https://raw.githubusercontent.com/DeSireFire/animeTrackerList/master/AT_all.txt
        https://raw.githubusercontent.com/XIU2/TrackersListCollection/master/all.txt
    '

    total_tracker=$((0))
    repeat_tracker=$((0))
    valid_tracker=$((0))

    # init json
    json_init

    for source in $sources; do
        echo ''
        echo "Tracker source: ${source}"

        content="$(wget -q -T 1 -O - ${source})"
        if [ -z "${content}" ]; then
            content="$(wget -q -T 5 -O - ${github_proxy}/${source})"
        fi
        if [ -z "${content}" ]; then
            echo "Tracker source invalid: ${source}"
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

                if json_is_a ${str_tracker} string; then
                    repeat_tracker=$((repeat_tracker + 1))
                    continue
                fi

                valid_tracker=$((valid_tracker + 1))
                json_add_string "${str_tracker}" "${valid_tracker}"
                json_add_string "${valid_tracker}" "${str_tracker}"
            done
        done
    done

    echo ''
    echo "total_tracker: ${total_tracker}, repeat_tracker: ${repeat_tracker}, valid_tracker: ${valid_tracker}"
    if [ ${valid_tracker} -le 0 ]; then
        echo ''
        echo 'no valid Tracker, update Tracker fail'
        return
    fi

    i=$((1))
    tracker_all_str=''
    uci -q delete aria2.main.bt_tracker
    while [ ${i} -le ${valid_tracker} ]; do
        json_get_var tracker ${i}
        uci add_list aria2.main.bt_tracker="${tracker}"
        if [ ${i} -le 1 ]; then
            tracker_all_str="${tracker}"
        else
            tracker_all_str="${tracker_all_str},${tracker}"
        fi
        i=$((i + 1))
    done

    uci commit aria2
}

config() {

    content="$(opkg list-installed aria2)"
    if [ -z "${content}" ]; then
        echo ''
        echo 'Aria2 not installed, Config Aria2 fail'
        return
    fi

    download_dir="${1}"
    download_dir_disk_type="${2}"

    if [ -z "${download_dir}" ]; then
        download_dir="$(uci -q get aria2.main.dir)"
    fi
    if [ -z "${download_dir}" ]; then
        download_dir='/etc/aria2/download/'
    fi
    if [ ! -d "${download_dir}" ]; then
        echo ''
        echo 'download_dir not exist, Config Aria2 fail'
        return
    fi

    trackers="$(uci -q get aria2.main.bt_tracker)"

    mems="$(free)"
    index=$((0))
    free=$((0))
    cache='4'
    if [ -n "${mems}" ]; then
        for mem in $mems; do
            index=$((index + 1))
            if [ $index -eq 10 ]; then
                free=$mem
                break
            fi
        done
    fi
    if [ ${free} -gt $((1024 * 4 * 1024)) ]; then
        cache='1024'
    elif [ ${free} -gt $((512 * 4 * 1024)) ]; then
        cache='512'
    elif [ ${free} -gt $((256 * 4 * 1024)) ]; then
        cache='256'
    elif [ ${free} -gt $((128 * 4 * 1024)) ]; then
        cache='128'
    elif [ ${free} -gt $((64 * 4 * 1024)) ]; then
        cache='64'
    elif [ ${free} -gt $((32 * 4 * 1024)) ]; then
        cache='32'
    elif [ ${free} -gt $((16 * 4 * 1024)) ]; then
        cache='16'
    elif [ ${free} -gt $((8 * 4 * 1024)) ]; then
        cache='8'
    fi

    uci -q delete aria2.main.bt_tracker
    uci -q delete aria2.main.extra_settings
    uci -q delete aria2.main

    uci set aria2.main=aria2
    uci set aria2.main.enabled='1'
    uci set aria2.main.user='aria2'
    uci set aria2.main.dir="${download_dir}"
    # input-file auto set
    uci set aria2.main.config_dir='/etc/aria2'
    # aria2.main.enable_logging can't set, if set, aria2 will start fail
    # aria2.main.log can't set, if set, aria2 will start fail
    uci set aria2.main.max_concurrent_downloads='50'
    # continue auto set
    uci set aria2.main.connect_timeout='10'
    uci set aria2.main.max_connection_per_server='16'
    uci add_list aria2.main.extra_settings='max-file-not-found=10'
    uci set aria2.main.max_tries='0'
    uci set aria2.main.min_split_size='4M'
    uci add_list aria2.main.extra_settings='netrc-path=/etc/aria2/.netrc'
    uci set aria2.main.retry_wait='10'
    uci add_list aria2.main.extra_settings='server-stat-of=/etc/aria2/server.status'
    uci add_list aria2.main.extra_settings='server-stat-if=/etc/aria2/server.status'
    uci set aria2.main.split='16'
    uci add_list aria2.main.extra_settings='stream-piece-selector=geom'
    uci set aria2.main.timeout='10'
    uci set aria2.main.http_accept_gzip='true'
    uci set aria2.main.user_agent='Transmission/3.00'
    uci set aria2.main.bt_detach_seed_only='true'
    uci set aria2.main.bt_enable_lpd='true'
    uci add_list aria2.main.extra_settings='bt-force-encryption=true'
    uci set aria2.main.bt_load_saved_metadata='true'
    uci set aria2.main.bt_max_peers='128'
    uci add_list aria2.main.extra_settings='bt-min-crypto-level=arc4'
    uci set aria2.main.bt_prioritize_piece='head'
    uci set aria2.main.bt_remove_unselected_file='true'
    uci add_list aria2.main.extra_settings='bt-require-crypto=true'
    uci set aria2.main.bt_request_peer_speed_limit='5'
    uci set aria2.main.bt_save_metadata='true'
    if [ -n "${trackers}" ]; then
        for tracker in $trackers; do
            if [ -z "$tracker" ]; then
                continue
            fi
            uci add_list aria2.main.bt_tracker="$tracker"
        done
    fi
    uci add_list aria2.main.extra_settings='bt-tracker-connect-timeout=10'
    uci add_list aria2.main.extra_settings='bt-tracker-timeout=10'
    uci add_list aria2.main.extra_settings='dht-entry-point=dht.transmissionbt.com:6881'
    uci add_list aria2.main.extra_settings='dht-entry-point6=dht.transmissionbt.com:6881'
    # dht-file-path auto set
    # dht-file-path6 auto set
    uci set aria2.main.dht_listen_port='51413'
    uci set aria2.main.enable_dht='true'
    uci set aria2.main.enable_dht6='true'
    uci set aria2.main.follow_torrent='false'
    uci set aria2.main.listen_port='51413'
    uci set aria2.main.peer_id_prefix='-TR3000-'
    uci add_list aria2.main.extra_settings='peer-agent=Transmission/3.00'
    uci set aria2.main.seed_ratio='0'
    # enable-rpc auto set
    # rpc-allow-origin-all auto set
    # rpc-listen-all auto set
    uci add_list aria2.main.extra_settings='rpc-max-request-size=10M'
    uci add_list aria2.main.extra_settings='allow-piece-length-change=true'
    uci add_list aria2.main.extra_settings='always-resume=false'
    uci set aria2.main.auto_save_interval='20'
    # conf-path auto set
    uci add_list aria2.main.extra_settings='content-disposition-default-utf8=true'
    uci set aria2.main.disk_cache="${cache}M"
    if [ -z "${download_dir_disk_type}" ]; then
        uci add_list aria2.main.extra_settings='enable-mmap=true'
        uci set aria2.main.file_allocation='falloc'
    elif [ "${download_dir_disk_type}" = 'SSD' ]; then
        uci set aria2.main.file_allocation='none'
    elif [ "${download_dir_disk_type}" = 'HDD' ]; then
        uci add_list aria2.main.extra_settings='enable-mmap=true'
        uci set aria2.main.file_allocation='falloc'
    else
        disk_type='HDD'
        uci add_list aria2.main.extra_settings='enable-mmap=true'
        uci set aria2.main.file_allocation='falloc'
    fi
    uci set aria2.main.force_save='true'
    uci add_list aria2.main.extra_settings='save-not-found=false'
    # aria2.main.log_level can't set, if set, aria2 will start fail
    uci add_list aria2.main.extra_settings='summary-interval=0'
    # save-session auto set
    uci set aria2.main.save_session_interval='20'

    uci commit aria2

    aria2_process="$(service aria2 status | grep 'running')"
    if [ -n "${aria2_process}" ]; then
        save_session
    fi
}

install() {

    download_dir="${1}"
    download_dir_disk_type="${2}"

    content="$(opkg list-installed aria2)"
    if [ -z "${content}" ]; then
        opkg update
        opkg install aria2
        config "${download_dir}" "${download_dir_disk_type}"
        echo ''
        echo 'Aria2 install success'
        return
    fi

    echo ''
    echo 'Aria2 already installed'
}

start() {

    download_dir="${1}"
    download_dir_disk_type="${2}"

    content="$(opkg list-installed aria2)"
    if [ -z "${content}" ]; then
        echo ''
        echo 'Aria2 not installed, start Aria2 fail'
        return
    fi

    aria2_process="$(service aria2 status | grep 'running')"
    if [ -n "${aria2_process}" ]; then
        save_session
        echo ''
        echo 'Aria2 running'
        return
    fi

    update_tracker
    config "${download_dir}" "${download_dir_disk_type}"
    service aria2 start

    aria2_process="$(service aria2 status | grep 'running')"
    if [ -n "${aria2_process}" ]; then
        echo ''
        echo 'Aria2 start success'
    else
        echo ''
        echo 'Aria2 start fail'
    fi
}

stop() {
    aria2_process="$(service aria2 status | grep 'running')"
    if [ -z "${aria2_process}" ]; then
        echo ''
        echo 'Aria2 not running'
        return
    fi

    save_session
    shutdown
    sleep 3s
    service aria2 stop
    sleep 1s

    aria2_process="$(service aria2 status | grep 'running')"
    if [ -n "${aria2_process}" ]; then
        echo ''
        echo 'Aria2 stop success'
    else
        echo ''
        echo 'Aria2 stop fail'
    fi
}

reload() {
    stop
    start
}

enable() {
    service aria2 enable
}

disable() {
    service aria2 disable
}

auto_update_tracker() {

    script_file_path="${1}"

    if [ ! -e "${script_file_path}" ]; then
        echo ''
        echo "${script_file_path} not exist, set auto update Tracker fail"
        return
    fi

    (
        crontab -l
        echo "0 4 * * * /bin/sh ${script_file_path} reload"
    ) | uniq | crontab -

    service cron restart
}

case ${1} in
'install')
    install "${2}" "${3}"
    ;;
'start')
    start "${2}" "${3}"
    ;;
'stop')
    stop
    ;;
'status')
    aria2_process="$(service aria2 status | grep 'running')"
    if [ -z "${aria2_process}" ]; then
        echo ''
        echo 'Aria2 not running'
    else
        echo ''
        echo 'Aria2 running'
    fi
    ;;
'reload')
    reload
    ;;
'enable')
    enable
    ;;
'disable')
    disable
    ;;
'auto_reload')
    auto_update_tracker "${2}"
    ;;
*)
    echo ''
    echo 'usage: /bin/sh aria2_tool_openwrt.sh install download_dir download_dir_disk_type'
    echo 'usage: /bin/sh aria2_tool_openwrt.sh start download_dir download_dir_disk_type'
    echo 'usage: /bin/sh aria2_tool_openwrt.sh stop'
    echo 'usage: /bin/sh aria2_tool_openwrt.sh status'
    echo 'usage: /bin/sh aria2_tool_openwrt.sh reload'
    echo 'usage: /bin/sh aria2_tool_openwrt.sh auto_reload script_file_path'
    ;;
esac
