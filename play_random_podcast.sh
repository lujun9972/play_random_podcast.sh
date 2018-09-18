#!/usr/bin/env bash

while getopts :c OPT; do
    case $OPT in
        c|+c)
            cached="True"
            ;;
        *)
            echo "usage: ${0##*/} [+-c} [--] podcast_feed..."
            exit 2
    esac
done
shift $(( OPTIND - 1 ))
OPTIND=1

podcast_feed=$1
random_enclosure=$(curl ${podcast_feed}|grep -i enclosure|grep -E -o "https*.*mp3" |shuf|head -n 1)
# 缓存mp3
if [[ -n ${cached} ]];then
    cd $(dirname $0)
    podcast=$(echo ${podcast_feed}|sed 's#^https*://\([^/]*\).*$#\1#')
    mkdir -p podcasts/${podcast}
    cd podcasts/${podcast}
    enclosure_file=$(basename ${random_enclosure})
    if [[ ! -f ${enclosure_file} ]];then
        wget ${random_enclosure}
    fi
    # 播放mp3文件
    mpg123 ${enclosure_file}
else
    # 播放mp3 URL
    curl ${random_enclosure}|mpg123 - # mpg123本身只支持http协议
fi
