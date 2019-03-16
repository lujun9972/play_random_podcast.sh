#!/usr/bin/env bash

while getopts :cs:p: OPT; do
    case $OPT in
        c|+c)
            cached="True"
            ;;
        s|+s)
            store_directory="$OPTARG"
            ;;
        p|+p)
            player="$OPTARG"
            ;;
        *)
            echo "usage: ${0##*/} [-c][-s STORE_DIRECTORY][-p PLAYER] [--] PODCAST_FEED"
            exit 2
    esac
done
shift $(( OPTIND - 1 ))
OPTIND=1

podcast_feed=$1
player=${player:-mpg123}
random_enclosure=$(curl -L ${podcast_feed} |grep -i '<enclosure' |grep -Eo 'url="[^">]+' |cut -d '"' -f2|shuf|head -n 1)
# 缓存mp3
if [[ -n ${cached} ]];then
    podcast=$(echo ${podcast_feed}|sed 's#^https*://\([^/]*\).*$#\1#')
    if [[ -z ${store_directory} ]];then
        store_directory=$(dirname $0)/podcasts/${podcast}
    fi
    mkdir -p ${store_directory}
    cd ${store_directory}
    enclosure_file="$(echo ${enclosure_file}|md5sum|cut -d " " -f1).$(basename ${random_enclosure})"
    if [[ ! -f ${enclosure_file} ]];then
        wget ${random_enclosure} -O ${enclosure_file}
    fi
    # 播放mp3文件
    $player "${enclosure_file}"
else
    # 播放mp3 URL
    curl -L ${random_enclosure}|$player - # mpg123本身只支持http协议
fi
